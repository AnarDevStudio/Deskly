#!/bin/bash
STATUS=$(playerctl status 2>/dev/null)
STATUS="${STATUS//$'\r'/}"
STATUS="${STATUS//$'\n'/}"
declare -rA ICONS=(
["Stopped"]=""
["Playing"]=""
["Paused"]=""
["Unknown"]=""
)
case "$STATUS" in
"") echo "" ;;
"Stopped") echo "${ICONS[Stopped]}" ;;
"Playing") echo "${ICONS[Playing]}" ;;
"Paused") echo "${ICONS[Paused]}" ;;
*) echo "${ICONS[Unknown]}" ;;
esac
exit 0
