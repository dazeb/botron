# Models

Decepticon routes LLM requests through a [LiteLLM](https://github.com/BerriAI/litellm) proxy, which supports Anthropic, OpenAI, Google, DeepSeek, xAI, Groq, Together AI, Fireworks, MiniMax, and Ollama backends with automatic failover.

---

## Model Profiles

Three profiles control which models are assigned to which agent roles.

### `eco` — Production (default)

Balanced cost and performance. Recommended for most engagements.

| Role | Primary | Fallback |
|------|---------|---------|
| Orchestrator | `claude-opus-4-6` | `gpt-5.4` |
| Planner | `claude-haiku-4-5` | `gemini-2.5-flash` |
| Exploit | `claude-sonnet-4-6` | `gpt-4.1` |
| Recon | `claude-haiku-4-5` | `gemini-2.5-flash` |
| Post-Exploit | `claude-sonnet-4-6` | `gpt-4.1` |

### `max` — High-value targets

Best models everywhere. Use for complex engagements where accuracy matters more than cost.

| Role | Primary | Fallback |
|------|---------|---------|
| Orchestrator | `claude-opus-4-6` | `gpt-5.4` |
| Planner | `claude-sonnet-4-6` | `claude-haiku-4-5` |
| Exploit | `claude-opus-4-6` | `claude-sonnet-4-6` |
| Recon | `claude-sonnet-4-6` | `claude-opus-4-6` |
| Post-Exploit | `claude-opus-4-6` | `claude-sonnet-4-6` |

### `test` — Development / CI

Fast models everywhere. Minimizes cost during development and automated testing.

| Role | Primary | Fallback |
|------|---------|---------|
| All roles | `claude-haiku-4-5` | — |

---

## Setting the Profile

In your `.env` file (edit with `decepticon config`):

```bash
BOTRON_MODEL_PROFILE=eco    # eco | max | test
```

The default is `eco` if not set.

---

## Fallback Chain

`ModelFallbackMiddleware` handles failover transparently. When the primary model returns an error (provider outage, rate limit, context length exceeded), it automatically retries with the fallback model.

The switch is seamless — the agent continues with no interruption.

---

## Supported Models

Models are referenced using LiteLLM's `provider/model` format in `decepticon/llm/models.py`.

| Provider | Model ID | Notes |
|----------|----------|-------|
| Anthropic | `anthropic/claude-opus-4-6` | Most capable reasoning |
| Anthropic | `anthropic/claude-sonnet-4-6` | Balanced performance |
| Anthropic | `anthropic/claude-haiku-4-5` | Fast, low cost |
| OpenAI | `openai/gpt-5.4` | GPT fallback for Opus |
| OpenAI | `openai/gpt-4.1` | GPT fallback for Sonnet |
| Google | `gemini/gemini-2.5-flash` | Fast Gemini fallback |
| DeepSeek | `deepseek/deepseek-chat` | Cost-effective reasoning |
| DeepSeek | `deepseek/deepseek-reasoner` | Deep reasoning mode |
| xAI | `xai/grok-4` | High-capability Grok |
| xAI | `xai/grok-4-mini` | Fast Grok |
| Groq | `groq/llama-3.3-70b-versatile` | Fast Meta Llama inference |
| Groq | `groq/llama-3.1-8b-instant` | Ultra-low latency |
| Groq | `groq/mixtral-8x7b-32768` | Mixtral MoE |
| Together AI | `together/meta-llama/Llama-4-Maverick` | Meta's latest |
| Together AI | `together/deepseek-ai/DeepSeek-V3` | DeepSeek on Together |
| Fireworks | `fireworks/llama-v3p1-70b-instruct` | Fast Llama 3.1 70B |
| MiniMax | `minimax/MiniMax-M2.7` | MiniMax model |
| Ollama | `ollama/llama3.2` | Local inference |

Any model supported by LiteLLM can be added. Edit `config/litellm.yaml` to add new providers or routes.

---

## LiteLLM Proxy

All LLM traffic flows through the LiteLLM proxy container (`port 4000`). This provides:

- **Unified API** — agents use one endpoint regardless of backend
- **Usage tracking** — token consumption per model, per agent role
- **Rate limiting** — configurable per provider
- **Billing aggregation** — cost attribution across providers

Configuration: `config/litellm.yaml`

Authentication: set `LITELLM_MASTER_KEY` in your `.env` file.

### Adding a New Provider

1. Add the model entry to `config/litellm.yaml`:
```yaml
  - model_name: provider/model-id
    litellm_params:
      model: provider/model-id
      api_key: os.environ/PROVIDER_API_KEY
```

2. Add the environment variable to `.env`:
```bash
PROVIDER_API_KEY=your-key
```

3. Add the model constant to `decepticon/llm/models.py` and assign it to agent roles.
