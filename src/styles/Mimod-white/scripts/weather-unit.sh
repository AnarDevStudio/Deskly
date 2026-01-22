#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
set -o allexport
source "$SCRIPT_DIR/config"
set +o allexport
REQUESTED_UNIT="${1:-temp}"
declare -rA UNITS=(
["metric_wind"]="m/s"
["metric_temp"]="°C"
["imperial_wind"]="mph"
["imperial_temp"]="°F"
["default_wind"]=""
["default_temp"]="°"
)
KEY="${UNIT:-default}_${REQUESTED_UNIT}"
echo "${UNITS[$KEY]:-°}"
exit 0
