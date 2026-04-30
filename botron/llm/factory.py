"""LLM Factory — creates ChatModel instances via LiteLLM proxy.

All LLM calls route through the LiteLLM Docker proxy for provider abstraction.
Provider API keys are configured in .env / docker-compose.yml.

Architecture:
    LLMFactory(proxy, mapping)
      → get_model("recon")  → ChatOpenAI(model="anthropic/claude-haiku-4-5")

Profile-aware: when no explicit mapping is provided, resolves
BOTRON_MODEL_PROFILE (eco/max/test) from BotronConfig.
"""

from __future__ import annotations

import httpx
from langchain_core.language_models import BaseChatModel
from langchain_openai import ChatOpenAI

from botron.core.logging import get_logger
from botron.llm.models import LLMModelMapping, ModelProfile, ProxyConfig
from botron.llm.router import ModelRouter

log = get_logger("llm.factory")


class LLMFactory:
    """Creates and caches LangChain ChatModel instances per agent role.

    Routes all models through LiteLLM proxy. Supports primary + fallback
    model resolution via ModelRouter.

    When constructed without an explicit mapping, uses the model profile
    from BotronConfig (env: BOTRON_MODEL_PROFILE).
    """

    def __init__(
        self,
        proxy: ProxyConfig | None = None,
        mapping: LLMModelMapping | None = None,
        profile: ModelProfile | str | None = None,
    ):
        self._proxy = proxy or self._resolve_proxy_config()
        if mapping is not None:
            self._mapping = mapping
        elif profile is not None:
            self._mapping = LLMModelMapping.from_profile(profile)
        else:
            self._mapping = self._resolve_profile_mapping()
        self._router = ModelRouter(self._mapping)
        self._cache: dict[str, BaseChatModel] = {}

    @staticmethod
    def _resolve_proxy_config() -> ProxyConfig:
        """Resolve proxy config from BotronConfig (env vars)."""
        from botron.core.config import load_config

        config = load_config()
        return ProxyConfig(
            url=config.llm.proxy_url,
            api_key=config.llm.proxy_api_key,
            timeout=config.llm.timeout,
            max_retries=config.llm.max_retries,
        )

    @staticmethod
    def _resolve_profile_mapping() -> LLMModelMapping:
        """Resolve model mapping from config's model_profile setting."""
        from botron.core.config import load_config

        config = load_config()
        return LLMModelMapping.from_profile(config.model_profile)

    @property
    def proxy_url(self) -> str:
        return self._proxy.url

    @property
    def router(self) -> ModelRouter:
        return self._router

    def get_model(self, role: str) -> BaseChatModel:
        """Get the primary ChatModel for a role. Cached per role."""
        if role in self._cache:
            return self._cache[role]

        assignment = self._router.get_assignment(role)
        log.info(
            "Creating LLM for role '%s' → model '%s' via %s",
            role,
            assignment.primary,
            self._proxy.url,
        )

        model = self._create_chat_model(assignment.primary, assignment.temperature)
        self._cache[role] = model
        return model

    def get_fallback_models(self, role: str) -> list[BaseChatModel]:
        """Get fallback ChatModel instances for a role. Empty if no fallback."""
        assignment = self._router.get_assignment(role)
        if not assignment.fallback:
            return []

        log.info(
            "Creating fallback LLM for role '%s' → model '%s'",
            role,
            assignment.fallback,
        )
        return [self._create_chat_model(assignment.fallback, assignment.temperature)]

    def _create_chat_model(self, model: str, temperature: float) -> BaseChatModel:
        """Create a ChatOpenAI instance routed through LiteLLM proxy."""
        import os

        # Nous Portal direct routing (bypasses LiteLLM proxy)
        NOUS_MODEL_MAP = {
            "nous/deepseek-v4-pro": "deepseek/deepseek-v4-pro",
            "nous/deepseek-v4-flash": "deepseek/deepseek-v4-flash",
            "nous/claude-sonnet-latest": "anthropic/claude-sonnet-latest",
            "nous/gpt-latest": "openai/gpt-latest",
        }
        if model in NOUS_MODEL_MAP:
            return ChatOpenAI(
                model=NOUS_MODEL_MAP[model],
                base_url="https://inference-api.nousresearch.com/v1",
                api_key=os.environ.get("NOUS_API_KEY", ""),
                temperature=temperature,
                timeout=self._proxy.timeout,
                max_retries=self._proxy.max_retries,
            )

        return ChatOpenAI(
            model=model,
            base_url=self._proxy.url,
            api_key=self._proxy.api_key,
            temperature=temperature,
            timeout=self._proxy.timeout,
            max_retries=self._proxy.max_retries,
        )

    async def health_check(self) -> bool:
        """Check if the LiteLLM proxy is reachable."""
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                resp = await client.get(f"{self._proxy.url}/health")
                return resp.status_code == 200
        except Exception:
            return False


def create_llm(
    role: str,
    config: object | None = None,
    profile: ModelProfile | str | None = None,
) -> BaseChatModel:
    """Convenience function — creates primary model for a role.

    Backward-compatible wrapper around LLMFactory.
    The `config` parameter is accepted but ignored (kept for call-site compat).
    Pass `profile` to override the config-level model profile.
    """
    factory = LLMFactory(profile=profile)
    role_str = role.value if hasattr(role, "value") else role
    return factory.get_model(role_str)
