#!/usr/bin/env bash
# Start GitaViśva on akhome. Binds to 127.0.0.1 only (never 0.0.0.0); Caddy fronts it at
# https://gita.int.akunamedia.studio (Tailscale only).
#   ./start-server.sh          dev server with hot reload (default)
#   ./start-server.sh --prod   production build, then next start
#   ./start-server.sh --detach run in the background under launchd (safe to close the terminal);
#                              combine with --prod; log: /tmp/gitaviswa.log
set -euo pipefail
cd "$(dirname "$0")"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"   # launchd starts with a minimal PATH
PORT="${PORT:-3100}"
HOST=127.0.0.1
LABEL=gitaviswa
LOG=/tmp/gitaviswa.log
DETACH=0; ARGS=()
for a in "$@"; do if [ "$a" = "--detach" ]; then DETACH=1; else ARGS+=("$a"); fi; done
set -- ${ARGS[@]+"${ARGS[@]}"}
[ -d node_modules ] || npm install --no-audit --no-fund
if lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port $PORT is already in use. Already running? https://gita.int.akunamedia.studio" >&2; exit 1
fi
if [ "$DETACH" = 1 ]; then
  launchctl remove "$LABEL" 2>/dev/null || true
  launchctl submit -l "$LABEL" -o "$LOG" -e "$LOG" -- "$PWD/start-server.sh" ${1:+"$1"}
  echo "Started in the background (launchd job '$LABEL'). Log: $LOG"
  echo "https://gita.int.akunamedia.studio (ready in a few seconds). Stop: ./stop-server.sh"
  exit 0
fi
echo "GitaViśva -> https://gita.int.akunamedia.studio  (local: http://$HOST:$PORT)"
if [ "${1:-}" = "--prod" ]; then
  npm run build
  exec npx next start -H "$HOST" -p "$PORT"
fi
exec npx next dev --turbopack -H "$HOST" -p "$PORT"
