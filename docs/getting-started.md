# Getting Started

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2
- An API key for at least one LLM provider (Anthropic, OpenAI, Google, DeepSeek, xAI, Groq, Together AI, Fireworks, or MiniMax)

That's it. Everything else runs inside containers.

---

## Install

```bash
git clone https://github.com/dazeb/botron.git
cd botron
```

No installer needed — all services run in Docker. The `make` targets handle everything.

---

## Configure

Create a `.env` file in the repo root with your API keys:

```bash
cp clients/launcher/internal/config/env.example .env
# Edit .env — add at least one LLM provider API key
# Set BOTRON_MODEL_PROFILE=eco (or max/test)
```

Minimal `.env`:

```env
# Required: at least one provider API key
ANTHROPIC_API_KEY=sk-ant-...
# or OPENAI_API_KEY=sk-...
# or DEEPSEEK_API_KEY=sk-...

# Model profile
BOTRON_MODEL_PROFILE=eco

# LiteLLM proxy (defaults work fine)
LITELLM_MASTER_KEY=sk-botron-master
LITELLM_SALT_KEY=sk-botron-salt
POSTGRES_PASSWORD=botron
NEO4J_PASSWORD=botron-graph
```

---

## Launch

**Start all services:**

```bash
make dev
```

This builds and starts all services with hot-reload:
- **LangGraph API** at `http://localhost:2024`
- **Web Dashboard** at `http://localhost:3000`
- **LiteLLM Proxy** at `http://localhost:4000`

**Open the CLI:**

```bash
make cli     # Interactive terminal UI (separate terminal)
```

Or start services without the CLI:

```bash
docker compose up -d --build
```

---

## Try the Demo

The demo runs a complete autonomous kill chain against a local Metasploitable 2 target — no setup needed beyond your API key.

```bash
make demo
```

**What happens:**
1. Metasploitable 2 is launched as a target VM
2. A pre-built engagement (RoE + OPPLAN) is loaded
3. The agent executes autonomously:
   - Port scan and service enumeration
   - vsftpd 2.3.4 backdoor exploitation
   - Sliver C2 implant deployment
   - Credential harvesting via C2 session
   - Internal network reconnaissance

The demo is read-only — it doesn't modify anything on your host.

---

## First Real Engagement

1. Start Botron (`make dev`) and open <http://localhost:3000>
2. The **Soundwave** agent interviews you to define the engagement:
   - Target scope (IP range, URL, Git repo, file upload, or local path)
   - Threat actor profile
   - Rules of Engagement (authorized scope, timing, exclusions)
3. Soundwave generates: **RoE → ConOps → Deconfliction Plan → OPPLAN**
4. You review and approve the OPPLAN
5. The autonomous loop begins

> **Important**: Only run Botron against systems you own or have explicit written authorization to test. See the disclaimer in the main README.

---

## Stopping Services

```bash
docker compose down      # Stop all services, keep data (volumes)
make clean               # Stop + remove all volumes (resets everything)
```

---

## Check Service Status

```bash
docker compose ps                  # Show running services
docker compose logs -f langgraph   # Follow LangGraph logs
docker compose logs -f litellm     # Follow LiteLLM logs
make health                        # Run health checks on all services
```

---

## Next Steps

| Topic | Doc |
|-------|-----|
| All CLI commands and keyboard shortcuts | [CLI Reference](cli-reference.md) |
| All `make` targets | [Makefile Reference](makefile-reference.md) |
| Agent roles and middleware | [Agents](agents.md) |
| Model profiles and fallback chain | [Models](models.md) |
| Engagement workflow (RoE → Execution) | [Engagement Workflow](engagement-workflow.md) |
| Web dashboard features | [Web Dashboard](web-dashboard.md) |
| Contributing to Botron | [Contributing](contributing.md) |
