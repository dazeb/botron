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

</div>

<br/>

> **Botron** is a fork of [Decepticon](https://github.com/PurpleAILAB/Decepticon) by PurpleAILAB, enhanced with multi-provider LLM support and stripped of proprietary Claude Code OAuth dependencies. All model routing is now handled through a single LiteLLM proxy endpoint supporting 10+ AI providers.

---

## What's Different from Upstream

| Feature | Upstream (Decepticon) | Botron |
|---------|----------------------|--------|
| **LLM Providers** | Anthropic-first (Opus/Sonnet/Haiku) | **Multi-provider**: Anthropic, OpenAI, Google, DeepSeek, xAI/Grok, Groq, Together AI, Fireworks, MiniMax, Ollama |
| **Auth Method** | API keys + Claude Code OAuth subscription | API keys only (clean LiteLLM proxy) |
| **Claude Code Handler** | 700-line OAuth spoofing handler | ❌ Removed |
| **Claude 4 Compat** | Trigger-term substitution for refusal bypass | ❌ Removed |
| **Model Selection** | Profile + Provider axes | Profile only (`BOTRON_MODEL_PROFILE`) |
| **Go Binary** | `decepticon` | `botron` |

---

## Install

**Prerequisites**: [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2.

```bash
git clone https://github.com/dazeb/botron.git
cd botron
make dev       # Start with hot-reload
make cli       # Interactive CLI (separate terminal)
```

Or start services directly:

```bash
docker compose up -d --build
# Web dashboard at http://localhost:3000
# LangGraph API at http://localhost:2024
```

→ **[Full setup guide](docs/getting-started.md)**

---

## Try the Demo

```bash
make demo
```

Launches Metasploitable 2, loads a pre-built engagement, and runs the full kill chain autonomously: port scan → vsftpd exploit → Sliver C2 implant → credential harvesting → internal recon.

---

## What is Botron?

The "AI + hacking" space is full of demos that run nmap and print a report. That's not what this is.

**Botron is a professional autonomous Red Team agent.** It executes realistic attack chains — reconnaissance, exploitation, privilege escalation, lateral movement, C2 — the way a real adversary would, not the way a scanner does.

But more importantly: it operates under the discipline that separates red teamers from script kiddies.

Before a single packet leaves the wire, Botron generates a complete engagement package:

- **RoE** (Rules of Engagement) — Authorized scope, exclusions, testing window, escalation contacts
- **ConOps** (Concept of Operations) — Threat actor profile, methodology, TTPs
- **Deconfliction Plan** — Source IPs, time windows, shared codes for real-time SOC deconfliction
- **OPPLAN** (Operations Plan) — Full mission plan with objectives, kill chain phases, and MITRE ATT&CK mapping

Every action operates inside defined rules. The agent doesn't just hack — it runs a professional Red Team operation that happens to be autonomous.

---

## Why Botron?

**Real kill chains, not checkbox scans.**
Botron reads an OPPLAN and pursues objectives through whatever path opens up — pivoting, adapting, chaining techniques — the way a real attacker would.

**Interactive shells, actually.**
Real offensive tools are interactive — `msfconsole`, `sliver-client`, `evil-winrm`. Most AI agents fire one-shot commands and give up. Botron runs every command inside persistent tmux sessions with automatic prompt detection. When a tool drops you into an interactive prompt, the agent sends follow-up commands. No workarounds.

**Real infrastructure isolation.**
All commands run inside a hardened Kali Linux sandbox on a dedicated operational network (`sandbox-net`), fully isolated from management (`botron-net`). LLM gateway, databases, and agent API live on one network; sandbox, C2 server, and targets live on another. Zero cross-network access. The agent controls the sandbox via Docker socket only.

**Multi-provider LLM routing.**
Botron routes all LLM calls through a [LiteLLM](https://github.com/BerriAI/litellm) proxy supporting 10+ AI providers with automatic failover. No vendor lock-in — use Anthropic, OpenAI, Google, DeepSeek, Grok, Groq, Together AI, Fireworks, MiniMax, or local Ollama models interchangeably.

**Offense serves defense.**
The [Offensive Vaccine](docs/offensive-vaccine.md) loop turns every finding into a defense improvement — automatically. Attack → defend → verify, at machine speed. This is Step 1 toward infrastructure that hardens itself.

---

## Architecture

Two isolated networks. Management and operations share zero network access.

<div align="center">
  <img src="assets/decepticon_infra.svg" alt="Botron Infrastructure" width="680">
</div>

→ **[Architecture deep dive](docs/architecture.md)**

---

## Agents

17 specialist agents organized by kill chain phase. Each agent starts with a fresh context window per objective — no accumulated noise.

| Phase | Agents |
|-------|--------|
| **Orchestration** | Botron (main), Soundwave (planning + docs) |
| **Reconnaissance** | Recon, Scanner |
| **Exploitation** | Exploit, Exploiter, Detector, Verifier, Patcher |
| **Post-Exploitation** | Post-Exploit |
| **Defense** | Defender (Offensive Vaccine loop) |
| **Specialists** | AD Operator, Cloud Hunter, Contract Auditor, Reverser, Analyst |

The vulnerability research pipeline (Scanner → Detector → Verifier → Exploiter → Patcher) handles the full lifecycle from discovery through proof-of-concept to patch proposal.

→ **[Agent details and middleware stack](docs/agents.md)**

---

## Models

Three profiles via LiteLLM proxy routing to **10+ AI providers**. Each role has a primary model and automatic fallback.

| Profile | Orchestrator | Exploit | Recon | Use case |
|---------|-------------|---------|-------|---------|
| **eco** (default) | Opus 4.6 | Sonnet 4.6 | Haiku 4.5 | Production |
| **max** | Opus 4.6 | Opus 4.6 | Sonnet 4.6 | High-value targets |
| **test** | Haiku 4.5 | Haiku 4.5 | Haiku 4.5 | Development / CI |

Set via `BOTRON_MODEL_PROFILE=eco` in your `.env`. Provider outage or rate limit → seamless fallback.

**Supported providers**: Anthropic · OpenAI · Google · DeepSeek · xAI/Grok · Groq · Together AI · Fireworks · MiniMax · Ollama (local)

→ **[Full model reference](docs/models.md)**

---

## Documentation

| Topic | Doc |
|-------|-----|
| Installation and first engagement | [Getting Started](docs/getting-started.md) |
| All CLI commands and keyboard shortcuts | [CLI Reference](docs/cli-reference.md) |
| All `make` targets | [Makefile Reference](docs/makefile-reference.md) |
| Agent roster and middleware | [Agents](docs/agents.md) |
| Model profiles and fallback chain | [Models](docs/models.md) |
| Skill system and format spec | [Skills](docs/skills.md) |
| Web dashboard features and setup | [Web Dashboard](docs/web-dashboard.md) |
| System architecture and network isolation | [Architecture](docs/architecture.md) |
| Neo4j knowledge graph | [Knowledge Graph](docs/knowledge-graph.md) |
| End-to-end engagement workflow | [Engagement Workflow](docs/engagement-workflow.md) |
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

Join the [Discord](https://discord.gg/TZUYsZgrRG) (upstream Decepticon community) — ask questions, share engagement logs, discuss techniques, or just connect with others building at the intersection of offense and defense.

---

## Credits

Botron is a fork of [Decepticon](https://github.com/PurpleAILAB/Decepticon) by [PurpleAILAB](https://github.com/PurpleAILAB). All credit for the original autonomous red team architecture, 17-agent orchestration system, hardened Kali sandbox, and Offensive Vaccine concept goes to the Decepticon team.

---

## Disclaimer

Do not use this project on any system or network without explicit written authorization from the system owner. Unauthorized access to computer systems is illegal. You are solely responsible for your actions. The authors and contributors assume no liability for misuse.

---

## License

[Apache-2.0](LICENSE)
