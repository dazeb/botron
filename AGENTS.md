# AGENTS.md — Botron Development Guide

## Architecture

Botron is an autonomous red team agent with 16 specialist agents orchestrated through LangGraph. All LLM traffic routes through a LiteLLM proxy (port 4000) in Docker Compose.

### Key Directories

```
botron/
  llm/           — Model factory, router, model definitions (models.py)
  agents/        — 16 specialist agents + prompt assembly
  tools/         — Tool implementations (web, reversing, cloud, research, reporting)
  core/          — Config, logging, engagement loop
config/
  litellm.yaml   — LiteLLM proxy model routing configuration
containers/      — Dockerfiles for each service
clients/
  launcher/      — Go CLI (onboard wizard, launcher)
  web/           — Next.js dashboard
```

## LLM Provider Architecture

### Model Definitions (`botron/llm/models.py`)

- `LLMModelMapping` is a Pydantic model with one `ModelAssignment` per agent role
- Each `ModelAssignment` has: `primary`, `fallback`, `temperature`, `max_tokens`
- Model names use LiteLLM provider-prefix format: `provider/model-id`
- `ModelProfile` enum: `ECO`, `MAX`, `TEST` — selected via `BOTRON_MODEL_PROFILE` env var
- `LLMModelMapping.from_profile("eco")` returns the default preset

### Adding a New Provider

1. Add the model constant in `models.py`:
```python
DEEPSEEK_CHAT = "deepseek/deepseek-chat"
```

2. Add the route in `config/litellm.yaml`:
```yaml
  - model_name: deepseek/deepseek-chat
    litellm_params:
      model: deepseek/deepseek-chat
      api_key: os.environ/DEEPSEEK_API_KEY
```

3. Assign it to agent roles in `LLMModelMapping` defaults or profile presets.

4. Add the env var to the `.env.example` template and onboard wizard.

### Model Routing

All model calls go through `LLMFactory` → `ChatOpenAI(model="provider/model-id", base_url=proxy_url)` → LiteLLM proxy → actual provider API.

No per-provider handler code needed — LiteLLM handles all provider differences.

## Key Conventions

- **Plans go in `plans/` at repo root**, not `.hermes/plans/`
- **AGENTS.md is the canonical agent instruction file** — update this when architecture changes
- **Docker Compose dual-network**: `botron-net` (management) and `sandbox-net` (operations)
- **All tools run in sandbox container** via Docker socket, not direct network access
- **Fresh context per objective** — each specialist agent starts with a clean context window

## Testing

```bash
# Python unit tests
make test

# Go launcher tests
cd clients/launcher && go test ./...
```
