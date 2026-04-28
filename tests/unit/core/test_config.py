"""Unit tests for decepticon.core.config"""

from botron.core.config import BotronConfig, load_config


class TestBotronConfig:
    def test_default_values(self):
        config = BotronConfig()
        assert config.debug is False

    def test_llm_defaults(self):
        config = BotronConfig()
        assert config.llm.proxy_url == "http://localhost:4000"
        assert config.llm.proxy_api_key == "sk-botron-master"

    def test_env_override(self, monkeypatch):
        monkeypatch.setenv("BOTRON_DEBUG", "true")
        config = BotronConfig()
        assert config.debug is True


class TestLoadConfig:
    def test_returns_defaults(self):
        config = load_config()
        assert config.llm.proxy_url == "http://localhost:4000"
        assert config.docker.sandbox_container_name == "botron-sandbox"
