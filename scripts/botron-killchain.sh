#!/usr/bin/env bash
# =============================================================================
# botron-killchain.sh — Full manual kill chain: recon → scan → exploit → post
# =============================================================================
# Usage: ./scripts/botron-killchain.sh [TARGET] [VULN] [SERVICE]
#
# Stages:
#   1. recon      → port discovery
#   2. scanner    → vulnerability detection
#   3. exploit    → gain initial access
#   4. postexploit → privilege escalation & credential harvest
#
# All stages share one thread ID (persistent engagement state).
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-192.168.1.1}"
VULN="${2:-vsftpd-3.0.3-backdoor}"
SERVICE="${3:-ftp}"

echo ""
echo "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
echo "▓  Botron Full Kill Chain                         ▓"
echo "▓  Target: $TARGET                                 ▓"
echo "▓  Exploit: $VULN                                 ▓"
echo "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
echo ""

# -- Stage 0: create thread and capture its ID
echo ""
echo "[STAGE 0] Creating persistent engagement thread..."
echo ""

# Run recon directly - it saves thread ID to ~/.botron/last-thread-id
"$SCRIPT_DIR/botron-recon.sh" "$TARGET" 2>&1

# Read back the thread ID
if [ -f ~/.botron/last-thread-id ]; then
    THREAD_ID=$(cat ~/.botron/last-thread-id)
    rm -f ~/.botron/last-thread-id
else
    echo "ERROR: Could not find thread ID file"
    exit 1
fi

echo "✓ Persistent Thread ID: $THREAD_ID"

# -- Stage 1: Scanner
echo ""
echo "[STAGE 1] Scanner: vulnerability detection ($SERVICE)"
echo ""
"$SCRIPT_DIR/botron-scanner.sh" -t "$THREAD_ID" "$TARGET" "$SERVICE"

# -- Stage 2: Exploit
echo ""
echo "[STAGE 2] Exploit: initial access ($VULN)"
echo ""
"$SCRIPT_DIR/botron-exploit.sh" -t "$THREAD_ID" "$TARGET" "$VULN"

# -- Stage 3: Post-Exploit
echo ""
echo "[STAGE 3] Post-Exploit: privilege escalation & credential harvest"
echo ""
"$SCRIPT_DIR/botron-postexploit.sh" -t "$THREAD_ID" "$TARGET"

# -- Summary
echo ""
echo "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
echo "▓  Kill Chain Complete                             ▓"
echo "▓  Thread ID: $THREAD_ID                            ▓"
echo "▓  Neo4j graph: http://localhost:7474               ▓"
echo "▓  Logs: docker compose logs -f langgraph            ▓"
echo "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
