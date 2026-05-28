#!/bin/sh
# entrypoint.sh — drop root if needed, then exec the binary
# Set BINARY env var to override default
if [ "$(id -u)" = "0" ]; then
  exec su-exec nobody ${BINARY:-/app/bin/goclaw} "$@"
fi
exec ${BINARY:-/app/bin/goclaw} "$@"
