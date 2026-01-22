#!/bin/bash
CACHE_FILE="$HOME/.cache/weather.json"
ARG="$1"
if [[ ! -f "$CACHE_FILE" ]]; then exit 1; fi
JQ_FILTER=""
case "$ARG" in temp) JQ_FILTER='.main.temp | tonumber | round | tostring' ;; name) JQ_FILTER='.name | ascii_upcase | .[0:30]' ;; desc) JQ_FILTER='.weather[0].description | gsub("(?<word>\\b\\w)"; (.word | ascii_upcase)) | .[0:22]' ;; wind) JQ_FILTER='.wind.speed | tostring' ;; humidity) JQ_FILTER='.main.humidity | tostring' ;; *) exit 1 ;; esac
DATA=$(jq -r "$JQ_FILTER" "$CACHE_FILE" 2>/dev/null)
if [[ -z "$DATA" ]]; then exit 1; fi
echo "$DATA"
