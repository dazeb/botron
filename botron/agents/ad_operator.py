"""AD Operator Agent — Active Directory and Windows attack lane."""

from __future__ import annotations

from pathlib import Path

from deepagents.backends import CompositeBackend, FilesystemBackend
from deepagents.middleware.filesystem import FilesystemMiddleware
from deepagents.middleware.patch_tool_calls import PatchToolCallsMiddleware
from deepagents.middleware.summarization import create_summarization_middleware
from langchain.agents import create_agent
from langchain.agents.middleware import ModelFallbackMiddleware
from langchain_anthropic.middleware import AnthropicPromptCachingMiddleware

from botron.agents.prompts import load_prompt
from botron.backends import DockerSandbox
from botron.core.config import load_config
from botron.llm import LLMFactory
from botron.middleware.skills import DecepticonSkillsMiddleware
from botron.tools.ad.tools import AD_TOOLS
from botron.tools.bash import bash
from botron.tools.bash.bash import set_sandbox
from botron.tools.references.tools import killchain_lookup
from botron.tools.research.tools import (
    kg_add_edge,
    kg_add_node,
    kg_ingest_asrep_hashes,
    kg_ingest_crackmapexec,
    kg_neighbors,
    kg_query,
    kg_stats,
)

_REPO_ROOT = Path(__file__).resolve().parents[2]


def create_ad_operator_agent():
    config = load_config()
    factory = LLMFactory()
    llm = factory.get_model("ad_operator")
    fallback_models = factory.get_fallback_models("ad_operator")

    sandbox = DockerSandbox(container_name=config.docker.sandbox_container_name)
    set_sandbox(sandbox)

    system_prompt = load_prompt("ad_operator", shared=["bash"])
    backend = CompositeBackend(
        default=sandbox,
        routes={"/skills/": FilesystemBackend(root_dir=_REPO_ROOT / "skills", virtual_mode=True)},
    )

    middleware = [
        DecepticonSkillsMiddleware(backend=backend, sources=["/skills/ad/", "/skills/shared/"]),
        FilesystemMiddleware(backend=backend),
    ]
    if fallback_models:
        middleware.append(ModelFallbackMiddleware(*fallback_models))
    middleware.extend(
        [
            create_summarization_middleware(llm, backend),
            AnthropicPromptCachingMiddleware(unsupported_model_behavior="ignore"),
            PatchToolCallsMiddleware(),
        ]
    )

    tools = [
        # AD tools
        *AD_TOOLS,
        # KG core + credential ingest
        kg_add_node,
        kg_add_edge,
        kg_query,
        kg_neighbors,
        kg_stats,
        kg_ingest_crackmapexec,
        kg_ingest_asrep_hashes,
        # References
        killchain_lookup,
        # Execution
        bash,
    ]
    agent = create_agent(
        llm,
        system_prompt=system_prompt,
        tools=tools,
        middleware=middleware,
        name="ad_operator",
    ).with_config({"recursion_limit": 250})
    return agent


graph = create_ad_operator_agent()
