#!/usr/bin/env bash
# =============================================================================
# botron-scanner.sh — Run vulnerability scanner agent on a thread
# =============================================================================
# Usage: ./scripts/botron-scanner.sh [-t THREAD_ID] [TARGET] [SERVICE]
# Default target: 192.168.1.1
# Default service: http (port 80)
# =============================================================================

set -euo pipefail

LANGGRAPH_URL="http://localhost:2024"
USAGE="Usage: $0 [-t THREAD_ID] [TARGET] [SERVICE]"

# Parse flags
THREAD_ID=""
while getopts "t:" opt; do
    case $opt in
        t) THREAD_ID="$OPTARG" ;;
        *) echo "$USAGE"; exit 1 ;;
    esac
done
shift $((OPTIND-1))

TARGET="${1:-192.168.1.1}"
SERVICE="${2:-http}"

# -- auto-escape target for JSON
ESC_TARGET=$(echo "$TARGET" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))')
ESC_SERVICE=$(echo "$SERVICE" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))')

# -- build prompt depending on service
if [ "$SERVICE" = "ssh" ]; then
    PROMPT="check $ESC_TARGET SSH banner grabbing and version detection"
elif [ "$SERVICE" = "ftp" ]; then
    PROMPT="check $ESC_TARGET FTP anonymous login vulnerability"
else
    PROMPT="scan $ESC_TARGET for $ESC_SERVICE vulnerabilities and outdated headers"
fi

echo "=== Botron Scanner ==="
echo "Target: $TARGET"
echo "Service: $SERVICE"
echo ""

# -- verify services
if ! curl -sf "$LANGGRAPH_URL/ok" >/dev/null 2>&1; then
    echo "ERROR: LangGraph not reachable. Run: docker compose up -d"
    exit 1
fi
echo "✓ LangGraph OK"

# -- create or reuse thread
if [ -z "$THREAD_ID" ]; then
    echo "→ Creating new engagement thread..."
    THREAD_JSON=$(curl -s -X POST "$LANGGRAPH_URL/threads" \
        -H "Content-Type: application/json" -d '{}')
    THREAD_ID=$(echo "$THREAD_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['thread_id'])")
    echo "✓ Thread ID: $THREAD_ID"
else
    echo "✓ Reusing Thread ID: $THREAD_ID"
fi

# -- launch scanner agent
echo ""
echo "→ Launching scanner agent..."
echo ""

curl -s -X POST "$LANGGRAPH_URL/runs/stream" \
    -H "Content-Type: application/json" \
    -d "{
        \"assistant_id\": \"scanner\",
        \"thread_id\": \"$THREAD_ID\",
        \"input\": {
            \"messages\": [{
                \"role\": \"user\",
                \"content\": $PROMPT
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
echo "=== Scanner complete ==="
echo "Thread ID: $THREAD_ID"
echo "View logs: docker compose logs -f langgraph"
