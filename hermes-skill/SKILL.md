---
name: botron
description: "Use when setting up, running, or managing the Botron autonomous red team agent — Docker-based multi-provider LLM pentesting framework. Covers install, demo, service management, testing, and provider configuration."
version: 1.0.0
author: dazeb
license: Apache-2.0
metadata:
  hermes:
    tags: [security, red-team, pentesting, docker, llm, autonomous-agents, liteLLM]
    requires_toolsets: [terminal, web]
    related_skills: [docker-management, env-setup]
---

# Botron — Autonomous Red Team Agent

Botron is a Docker-based autonomous red team agent with 17 specialist agents orchestrated through LangGraph. It routes all LLM calls through a LiteLLM proxy supporting **10+ AI providers** with automatic failover.

Fork of [Decepticon](https://github.com/PurpleAILAB/Decepticon) by PurpleAILAB, enhanced with multi-provider support and stripped of proprietary Claude Code OAuth dependencies.

## When to Use

- Setting up Botron for the first time
- Running the Metasploitable 2 demo
- Managing Docker Compose services (start, stop, logs, health)
- Running the Python test suite
- Configuring LLM providers
- Debugging service startup issues

## Quick Start

```bash
# Clone and enter
git clone https://github.com/dazeb/botron.git ~/projects/botron
cd ~/projects/botron

# Configure (create .env with at least one API key)
cp clients/launcher/internal/config/env.example .env
# Edit .env — set ANTHROPIC_API_KEY, OPENAI_API_KEY, or any provider key
# Set BOTRON_MODEL_PROFILE=eco (or max, test)

# Add required defaults
cat >> .env << 'EOF'
LITELLM_MASTER_KEY=sk-botron-master
LITELLM_SALT_KEY=sk-botron-salt
POSTGRES_PASSWORD=botron
NEO4J_PASSWORD=botron-graph
EOF

# Start all services
make dev
# or: docker compose up -d --build

# Open CLI in separate terminal
make cli
```

## Service Management

All commands from `~/projects/botron/`:

```bash
# Start services with hot-reload
make dev

# Start services (no watch mode)
docker compose up -d --build

# Check status
docker compose ps
make status

# Health checks
make health

# View logs
docker compose logs -f langgraph
docker compose logs -f litellm

# Stop (keep data)
docker compose down

# Stop + remove all volumes (full reset)
make clean
```

## Run the Demo

```bash
cd ~/projects/botron
make demo
```

Launches Metasploitable 2, loads a pre-built engagement, and runs the full kill chain autonomously: port scan → vsftpd exploit → Sliver C2 implant → credential harvesting → internal recon.

## Run Tests

```bash
cd ~/projects/botron

# Python tests (local venv)
python3 -m venv .venv
.venv/bin/pip install pydantic pydantic-settings pyyaml pytest httpx "langchain-core>=0.3.0" "langchain-openai>=0.3.0"
.venv/bin/python -m pytest tests/unit/ -v

# Python tests (in Docker)
docker compose exec langgraph pip install pytest
docker compose exec langgraph python -m pytest tests/unit/ -v

# Go launcher tests
cd clients/launcher && go test ./...
```

## Architecture

```
botron/
├── botron/              # Python package — agents, LLM, tools, middleware
│   ├── llm/             # Model factory, router, model definitions
│   ├── agents/          # 17 specialist agents + prompts
│   ├── tools/           # Security tools (web, reversing, cloud, AD, research)
│   └── core/            # Config, logging, engagement loop
├── config/
│   └── litellm.yaml     # LiteLLM proxy model routing (10+ providers)
├── containers/          # Dockerfiles for each service
├── clients/
│   ├── launcher/        # Go CLI (onboard wizard, launcher)
│   └── web/             # Next.js dashboard
└── langgraph.json       # LangGraph graph definitions (17 agents)
```

### Docker Compose Services

| Service | Port | Purpose |
|---------|------|---------|
| `botron-postgres` | 5432 | LiteLLM + web dashboard DB |
| `botron-neo4j` | 7474/7687 | Attack chain knowledge graph |
| `botron-litellm` | 4000 | LLM API gateway (10+ providers) |
| `botron-langgraph` | 2024 | Agent API server |
| `botron-sandbox` | — | Hardened Kali red-team sandbox |
| `botron-web` | 3000 | Next.js dashboard |

### Supported LLM Providers

| Provider | Models | Env Var |
|----------|--------|---------|
| Anthropic | Opus 4.6, Sonnet 4.6, Haiku 4.5 | `ANTHROPIC_API_KEY` |
| OpenAI | GPT-5.4, GPT-4.1 | `OPENAI_API_KEY` |
| Google | Gemini 2.5 Flash | `GEMINI_API_KEY` |
| DeepSeek | DeepSeek-Chat, DeepSeek-Reasoner | `DEEPSEEK_API_KEY` |
| xAI | Grok-4, Grok-4-Mini | `XAI_API_KEY` |
| Groq | Llama 3.3 70B, Llama 3.1 8B, Mixtral | `GROQ_API_KEY` |
| Together AI | Llama 4 Maverick, DeepSeek-V3 | `TOGETHER_API_KEY` |
| Fireworks | Llama 3.1 70B | `FIREWORKS_API_KEY` |
| MiniMax | M2.7 | `MINIMAX_API_KEY` |
| Ollama | llama3.2 (local) | `OLLAMA_API_BASE` |

## Common Pitfalls

1. **Missing `.env` file** — Docker Compose requires `.env` at repo root. Copy from `clients/launcher/internal/config/env.example` and add at least one API key.

2. **LangGraph fails to start** — Check `langgraph.json` graph paths. All 17 agents must point to `./botron/agents/<name>.py:graph`. If paths reference `./decepticon/` you're on an old version.

3. **LiteLLM can't reach providers** — Verify API keys are set in `.env`. Test directly:
   ```bash
   curl -X POST http://localhost:4000/chat/completions \
     -H "Authorization: Bearer sk-botron-master" \
     -H "Content-Type: application/json" \
     -d '{"model":"anthropic/claude-haiku-4-5","messages":[{"role":"user","content":"hi"}]}'
   ```

4. **Old Decepticon containers conflict** — If you previously ran upstream Decepticon, tear down first:
   ```bash
   docker compose --profile cli --profile victims down --volumes
   docker network rm decepticon-net 2>/dev/null
   ```

5. **Python tests fail with import errors** — The project depends on langchain, httpx, etc. Install full deps in a venv first (see test section above).

6. **`make dev` uses old code** — Rebuild images after code changes:
   ```bash
   docker compose build langgraph litellm
   docker compose up -d --wait langgraph
   ```

## Verification Checklist

- [ ] `.env` exists with at least one API key and `BOTRON_MODEL_PROFILE`
- [ ] `docker compose ps` shows all services healthy
- [ ] `curl -s http://localhost:2024/ok` returns `{"ok":true}`
- [ ] `curl -s http://localhost:4000/health` returns 200
- [ ] `make health` passes all checks
- [ ] `docker compose exec langgraph python -m pytest tests/unit/llm/ -q` passes
