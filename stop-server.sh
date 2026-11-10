#!/usr/bin/env bash
# Stop the GitaViśva server started by start-server.sh (whatever is listening on its port).
set -euo pipefail
PORT="${PORT:-3100}"
# Remove the launchd job first (a --detach start), or it would not stay stopped.
launchctl remove gitaviswa 2>/dev/null || true
pids=$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)
if [ -z "$pids" ]; then echo "Nothing is listening on port $PORT."; exit 0; fi
kill $pids
for _ in 1 2 3 4 5; do
  sleep 1
  lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1 || { echo "Stopped (port $PORT free)."; exit 0; }
done
echo "Still running after 5s; forcing."; kill -9 $pids; echo "Stopped."
