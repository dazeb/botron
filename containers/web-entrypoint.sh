#!/bin/sh
set -e

cd /app/clients/web

echo "[botron-web] Running DB migrations..."
npx prisma migrate deploy

echo "[botron-web] Starting terminal server (ws://0.0.0.0:${TERMINAL_PORT:-3003})..."
npx tsx server/terminal-server.ts &

echo "[botron-web] Starting Next.js (standalone)..."
exec node server.js
