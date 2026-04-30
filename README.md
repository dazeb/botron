[![English](https://img.shields.io/badge/Language-English-blue?style=for-the-badge)](README.md)
[![한국어](https://img.shields.io/badge/Language-한국어-red?style=for-the-badge)](README_KO.md)

<div align="center">
  <h1>🤖 Botron — Autonomous Red Team Agent</h1>
</div>

<p align="center"><i>"Another AI hacker? Let us guess — it runs nmap and writes a report."</i></p>

<div align="center">

<a href="https://github.com/dazeb/botron/blob/main/LICENSE">
  <img src="https://img.shields.io/github/license/dazeb/botron?style=for-the-badge&color=blue" alt="License: Apache 2.0">
</a>
<a href="https://github.com/dazeb/botron/stargazers">
  <img src="https://img.shields.io/github/stars/dazeb/botron?style=for-the-badge&color=yellow" alt="Stargazers">
</a>
<a href="https://github.com/dazeb/botron/network/members">
  <img src="https://img.shields.io/github/forks/dazeb/botron?style=for-the-badge&color=orange" alt="Forks">
</a>

<br/>

<a href="https://discord.gg/TZUYsZgrRG">
  <img src="https://img.shields.io/badge/Discord-Join%20Us-7289DA?logo=discord&logoColor=white&style=for-the-badge" alt="Join us on Discord">
</a>
<a href="https://github.com/dazeb/botron">
  <img src="https://img.shields.io/badge/Repo-dazeb/botron-181717?logo=github&logoColor=white&style=for-the-badge" alt="GitHub">
</a>
<a href="https://github.com/dazeb/botron/blob/main/hermes-skill/SKILL.md">
  <img src="https://img.shields.io/badge/Hermes-Skill_Pack-8B5CF6?logo=bookstack&logoColor=white&style=for-the-badge" alt="Hermes Skill">
</a>

</div>

<br/>

> **Botron** is a fork of [Decepticon](https://github.com/PurpleAILAB/Decepticon) by PurpleAILAB, enhanced with multi-provider LLM support and stripped of proprietary Claude Code OAuth dependencies. All model routing is handled through a single LiteLLM proxy endpoint supporting 12+ AI providers including OpenRouter and local Ollama models.

---

## What's Different from Upstream

| Feature | Upstream (Decepticon) | Botron |
|---------|----------------------|--------|
| **LLM Providers** | Anthropic-first (Opus/Sonnet/Haiku) | **12+ providers**: Anthropic, OpenAI, Google, DeepSeek, xAI/Grok, Groq, Together AI, Fireworks, MiniMax, **OpenRouter**, **Ollama** (local), **Nous Portal** |
| **Model Profiles** | 3 (eco, max, test) | **5** — adds `local` (OpenRouter + Ollama) and `nous` (DeepSeek V4 via Nous Portal) |
| **Auth Method** | API keys + Claude Code OAuth subscription | API keys + OpenRouter + Nous (Hermes agent_key) + Ollama (local) |
| **Claude Code Handler** | 700-line OAuth spoofing handler | ❌ Removed |
| **Claude 4 Compat** | Trigger-term substitution for refusal bypass | ❌ Removed |
| **Local LLM** | Basic Ollama route | **3 Ollama models** (qwen2.5-7b, qwen3.5-abliterated 9B, gemma4-regular) |
| **Go Binary** | `decepticon` | `botron` |
| **Hermes Agent** | — | **Skill pack** — `hermes skills tap add dazeb/botron` |

---

## Quick Start

**Prerequisites**: [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2.

```bash
git clone https://github.com/dazeb/botron.git
cd botron

# Configure
cp clients/launcher/internal/config/env.example .env
# Edit .env — add at least one API key (Anthropic, OpenAI, OpenRouter, or Nous)

# For Nous Portal (DeepSeek V4) via Hermes Agent:
#   BOTRON_MODEL_PROFILE=nous
#   NOUS_API_KEY=sk-nous-...          # from ~/.hermes/auth.json
#
# For free local testing with Ollama (requires GPU):
#   OLLAMA_API_BASE=http://host.docker.internal:11434
#   BOTRON_MODEL_PROFILE=local
#   OPENROUTER_API_KEY=sk-or-...      # needed for orchestrator reasoning

# Start
make dev       # All services with hot-reload
make cli       # Interactive CLI (separate terminal)
```

→ **[Full setup guide](docs/getting-started.md)**

---

## Try the Demo

```bash
make demo
```

Launches Metasploitable 2, loads a pre-built engagement, and runs the full kill chain autonomously: port scan → vsftpd exploit → Sliver C2 implant → credential harvesting → internal recon.

> **Demo requires API credits** (OpenRouter or Anthropic) — the orchestrator needs Claude/GPT-level reasoning. Sub-agents can use local Ollama models. See [Model Profiles](#models) below.

---

## What is Botron?

The "AI + hacking" space is full of demos that run nmap and print a report. That's not what this is.

**Botron is a professional autonomous Red Team agent.** It executes realistic attack chains — reconnaissance, exploitation, privilege escalation, lateral movement, C2 — the way a real adversary would, not the way a scanner does. Every action operates inside defined Rules of Engagement.

Before a single packet leaves the wire, Botron generates a complete engagement package:

- **RoE** (Rules of Engagement) — Authorized scope, exclusions, testing window
- **ConOps** (Concept of Operations) — Threat actor profile, methodology, TTPs
- **Deconfliction Plan** — Source IPs, time windows, SOC deconfliction
- **OPPLAN** (Operations Plan) — Full mission plan with MITRE ATT&CK mapping

---

## Why Botron?

**Real kill chains, not checkbox scans.** Reads an OPPLAN and pursues objectives through whatever path opens up — pivoting, adapting, chaining techniques.

**Interactive shells.** Runs every command inside persistent tmux sessions with automatic prompt detection. When a tool drops into an interactive prompt (`msfconsole`, `sliver-client`), the agent sends follow-up commands.

**Infrastructure isolation.** Hardened Kali Linux sandbox on `sandbox-net`, fully isolated from management (`botron-net`). Zero cross-network access.

**Multi-provider LLM routing.** LiteLLM proxy with 12+ providers and automatic failover. Mix and match — OpenRouter for reasoning, Ollama for tactical work.

**Offense serves defense.** The [Offensive Vaccine](docs/offensive-vaccine.md) loop turns every finding into a defense improvement automatically.

---

## Architecture

Two isolated networks. Management and operations share zero network access.

<div align="center">
  <img src="assets/decepticon_infra.svg" alt="Botron Infrastructure" width="680">
</div>

---

## Agents

17 specialist agents organized by kill chain phase. Fresh context window per objective — no accumulated noise.

| Phase | Agents |
|-------|--------|
| **Orchestration** | Botron (main), Soundwave (planning + docs) |
| **Reconnaissance** | Recon, Scanner |
| **Exploitation** | Exploit, Exploiter, Detector, Verifier, Patcher |
| **Post-Exploitation** | Post-Exploit |
| **Defense** | Defender (Offensive Vaccine loop) |
| **Specialists** | AD Operator, Cloud Hunter, Contract Auditor, Reverser, Analyst |

Pipeline: Scanner → Detector → Verifier → Exploiter → Patcher

---

## Models

Four profiles via LiteLLM proxy. Each agent role has a primary model + automatic fallback.

| Profile | Orchestrator | Exploit | Recon | Cost |
|---------|-------------|---------|-------|------|
| **eco** | Opus 4.6 | Sonnet 4.6 | Haiku 4.5 | $$$ |
| **max** | Opus 4.6 | Opus 4.6 | Sonnet 4.6 | $$$$ |
| **test** | Haiku 4.5 | Haiku 4.5 | Haiku 4.5 | $ |
| **local** | Sonnet 4.6 (OpenRouter) | Sonnet 4.6 (OpenRouter) | qwen2.5-7b (Ollama) | $$ |
| **nous** | DeepSeek V4 Pro (Nous) | DeepSeek V4 Flash (Nous) | DeepSeek V4 Flash (Nous) | $ |

Set via `BOTRON_MODEL_PROFILE=nous` in `.env`. The `nous` profile uses:
- **Nous Portal** (`inference-api.nousresearch.com/v1`) for all agent roles
- **DeepSeek V4 Flash** as primary (fast, cheap, tool-calling enabled)
- **DeepSeek V4 Pro** as fallback (higher reasoning quality)
- Authenticates via your Hermes Agent `agent_key` — no separate DeepSeek API key needed

The `local` profile uses:
- **OpenRouter** for reasoning-heavy roles (botron, exploit, soundwave, vulnresearch)
- **Ollama** for tactical/scanner roles (recon, scanner, detector, cloud, AD, reverser)

**Supported providers**: Anthropic · OpenAI · Google · DeepSeek · xAI/Grok · Groq · Together AI · Fireworks · MiniMax · **OpenRouter** · **Ollama** (local) · **Nous Portal**

### Nous Portal (DeepSeek V4)

The `nous` profile routes all agent traffic through [Nous Portal](https://nousresearch.com/) using your existing Hermes Agent `agent_key`. No separate DeepSeek API key required.

**Setup:**
```bash
# 1. Grab your agent_key from Hermes auth
cat ~/.hermes/auth.json | jq -r '.agent_key'

# 2. Add to .env
NOUS_API_KEY=sk-nous-your-key-here
BOTRON_MODEL_PROFILE=nous

# 3. Restart containers
docker compose up -d
```

**How it works:**
- `botron/llm/factory.py` detects `nous/*` model names and bypasses the LiteLLM proxy, routing directly to `https://inference-api.nousresearch.com/v1`
- `botron/llm/models.py` maps the `nous` profile to DeepSeek V4 Flash (primary) and V4 Pro (fallback)
- All 16 agent roles get tool-calling enabled models — confirmed `finish_reason: "tool_calls"` on recon, scanner, exploit, and post-exploit stages

## Running a Killchain

Botron includes POSIX shell scripts in `scripts/` for manual killchain execution against a target. All stages share a persistent thread ID (engagement state).

### Prerequisites
- Docker Compose services running: `docker compose up -d`
- LangGraph health: `curl http://localhost:2024/ok` → `{"ok":true}`
- LiteLLM health: `curl http://localhost:4000/health/readiness`
- A valid model profile in `.env` (`eco`, `max`, `test`, `local`, or `nous`)

### Individual Stages

| Stage | Script | Purpose |
|-------|--------|---------|
| Recon | `./scripts/botron-recon.sh [TARGET]` | Port discovery, service enumeration |
| Scanner | `./scripts/botron-scanner.sh -t THREAD_ID [TARGET] [SERVICE]` | Vulnerability detection |
| Exploit | `./scripts/botron-exploit.sh -t THREAD_ID [TARGET] [VULN]` | Initial access |
| Post-Exploit | `./scripts/botron-postexploit.sh -t THREAD_ID [HOST]` | Privesc, credential harvest, lateral movement |

### Full Killchain (One Command)

```bash
./scripts/botron-killchain.sh [TARGET] [VULN] [SERVICE]
```

**Example against Metasploitable 2:**
```bash
cd ~/projects/botron
./scripts/botron-killchain.sh 192.168.8.203 vsftpd-3.0.3-backdoor ftp
```

This executes:
1. **Recon** → creates engagement thread, runs nmap port scan
2. **Scanner** → detects FTP anonymous login / vsftpd backdoor
3. **Exploit** → gains initial access via vsftpd backdoor
4. **Post-Exploit** → privilege escalation & credential extraction

All output streams live. Each stage passes the same `thread_id` so the knowledge graph accumulates state across the full chain.

### Monitoring

```bash
# Live logs
docker compose logs -f langgraph

# Knowledge graph (Neo4j)
open http://localhost:7474

# Thread state
curl http://localhost:2024/threads/$THREAD_ID | jq
```

---

## Documentation

| Topic | Doc |
|-------|-----|
| Installation and first engagement | [Getting Started](docs/getting-started.md) |
| CLI commands and keyboard shortcuts | [CLI Reference](docs/cli-reference.md) |
| All `make` targets | [Makefile Reference](docs/makefile-reference.md) |
| Agent roster and middleware | [Agents](docs/agents.md) |
| Model profiles and fallback chain | [Models](docs/models.md) |
| Skill system and format spec | [Skills](docs/skills.md) |
| Web dashboard features | [Web Dashboard](docs/web-dashboard.md) |
| Architecture and network isolation | [Architecture](docs/architecture.md) |
| Neo4j knowledge graph | [Knowledge Graph](docs/knowledge-graph.md) |
| Engagement workflow (RoE → Execution) | [Engagement Workflow](docs/engagement-workflow.md) |
| Offensive Vaccine loop | [Offensive Vaccine](docs/offensive-vaccine.md) |
| Contributing to Botron | [Contributing](docs/contributing.md) |

---

## Contributing

```bash
git clone https://github.com/dazeb/botron.git
cd botron
make dev     # Start with hot-reload
make cli     # Open the interactive CLI (separate terminal)
```

→ **[Contributing guide](docs/contributing.md)**

---

## Community

Join the [Discord](https://discord.gg/TZUYsZgrRG) (upstream Decepticon community) — ask questions, share engagement logs, discuss techniques.

---

## Credits

Botron is a fork of [Decepticon](https://github.com/PurpleAILAB/Decepticon) by [PurpleAILAB](https://github.com/PurpleAILAB). All credit for the original autonomous red team architecture, 17-agent orchestration system, hardened Kali sandbox, and Offensive Vaccine concept goes to the Decepticon team.

---

## Disclaimer

Do not use this project on any system or network without explicit written authorization from the system owner. Unauthorized access to computer systems is illegal. You are solely responsible for your actions.

---

## License

[Apache-2.0](LICENSE)
