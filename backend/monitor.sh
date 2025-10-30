#!/usr/bin/env bash

set -euo pipefail

# Simple helper to control monitoring via the backend API
# Defaults can be overridden via environment variables:
#   MONITOR_BASE_URL (default: http://127.0.0.1:8000)
#   MONITOR_INTERFACE (default: any)
#   MONITOR_THRESHOLD (default: 0.5)

BASE_URL=${MONITOR_BASE_URL:-http://127.0.0.1:8000}
IFACE=${MONITOR_INTERFACE:-any}
THRESHOLD=${MONITOR_THRESHOLD:-0.5}

usage() {
  cat <<EOF
Usage: $(basename "$0") <start|stop|status|wait-active>

Commands:
  start         Start monitoring (interface="${IFACE}", threshold=${THRESHOLD})
  stop          Stop monitoring
  status        Show monitoring status
  wait-active   Poll until status becomes ACTIVE (or 30s timeout)

Environment overrides:
  MONITOR_BASE_URL   Backend base URL (default: ${BASE_URL})
  MONITOR_INTERFACE  Capture interface   (default: ${IFACE})
  MONITOR_THRESHOLD  Detection threshold (default: ${THRESHOLD})
EOF
}

start_monitoring() {
  curl -s -X POST "${BASE_URL}/api/monitor/start" \
    -H "Content-Type: application/json" \
    -d "{\"interface\":\"${IFACE}\",\"threshold\":${THRESHOLD}}" | cat
  echo
}

stop_monitoring() {
  curl -s -X POST "${BASE_URL}/api/monitor/stop" | cat
  echo
}

show_status() {
  curl -s "${BASE_URL}/api/monitor/status" | cat
  echo
}

wait_active() {
  local deadline=$((SECONDS + 30))
  while (( SECONDS < deadline )); do
    local s
    s=$(curl -s "${BASE_URL}/api/monitor/status" || true)
    echo "Status: ${s}"
    if echo "${s}" | grep -q '"active":\s*true'; then
      echo "Monitoring is ACTIVE"
      return 0
    fi
    sleep 1
  done
  echo "Timed out waiting for ACTIVE status" >&2
  return 1
}

cmd=${1:-}
case "${cmd}" in
  start)
    start_monitoring
    ;;
  stop)
    stop_monitoring
    ;;
  status)
    show_status
    ;;
  wait-active)
    wait_active
    ;;
  *)
    usage
    exit 1
    ;;
esac


