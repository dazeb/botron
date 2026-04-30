#!/usr/bin/env bash
# =============================================================================
# botron-recon.sh — Create engagement thread and fire recon agent
# =============================================================================
# Usage: ./scripts/botron-recon.sh [TARGET_IP]
# Default target: 192.168.1.1
#
# Requires: curl, jq (or python3)
# Services must be up: docker compose ps (all healthy)
# =============================================================================

set -euo pipefail

TARGET="${1:-192.168.1.1}"
LANGGRAPH_URL="http://localhost:2024"

echo "=== Botron Recon Launcher ==="
echo "Target: $TARGET"
echo ""

# -----------------------------------------------------------------------------
# 1. Verify services are up
# -----------------------------------------------------------------------------
if ! curl -sf "$LANGGRAPH_URL/ok" >/dev/null 2>&1; then
    echo "ERROR: LangGraph not reachable at $LANGGRAPH_URL/ok"
    echo "Run: cd ~/projects/botron && docker compose up -d"
    exit 1
fi
echo "✓ LangGraph OK"

if ! curl -sf http://localhost:4000/health/readiness >/dev/null 2>&1; then
    echo "ERROR: LiteLLM not reachable"
    exit 1
fi
echo "✓ LiteLLM OK"

# -----------------------------------------------------------------------------
# 2. Create thread (engagement)
# -----------------------------------------------------------------------------
echo ""
echo "→ Creating engagement thread..."

THREAD_JSON=$(curl -s -X POST "$LANGGRAPH_URL/threads" \
    -H "Content-Type: application/json" \
    -d '{}')

# Extract thread_id with jq if available, else python3 fallback
if command -v jq >/dev/null 2>&1; then
    THREAD_ID=$(echo "$THREAD_JSON" | jq -r '.thread_id')
else
    THREAD_ID=$(echo "$THREAD_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['thread_id'])")
fi

echo "✓ Thread ID: $THREAD_ID"

# -----------------------------------------------------------------------------
# 3. Fire recon agent
# -----------------------------------------------------------------------------
echo ""
echo "→ Launching recon agent: nmap scan $TARGET -p-"
echo "    (streaming output below)"
echo ""

curl -s -X POST "$LANGGRAPH_URL/runs/stream" \
    -H "Content-Type: application/json" \
    -d "{
        \"assistant_id\": \"recon\",
        \"thread_id\": \"$THREAD_ID\",
        \"input\": {
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"Perform a full port scan on $TARGET. Enumerate services and versions. Store results in the knowledge graph.\"
            }]
        },
        \"stream_mode\": [\"values\"]
    }" | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if line.startswith('event:'): print(f'\n[EVENT {line[6:].strip()}]'); continue
    if line.startswith('data:'):
        try: data=json.loads(line[5:].strip()); print(json.dumps(data, indent=2)[:2000])
        except: print(line[:500])
"

echo ""
echo "=== Recon complete ==="
echo "Thread ID: $THREAD_ID"
echo "View logs: docker compose logs -f langgraph"
echo "Neo4j graph: http://localhost:7474"

# Save thread ID for downstream scripts
mkdir -p ~/.botron 2>/dev/null
echo "$THREAD_ID" > ~/.botron/last-thread-id
