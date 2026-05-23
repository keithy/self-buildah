#!/bin/sh
# entrypoint.sh — drop root if needed, then exec the binary
if [ "$(id -u)" = "0" ]; then
  exec su-exec nobody /app/bin/goclaw "$@"
fi
exec /app/bin/goclaw "$@"
