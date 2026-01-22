#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
set -o allexport
source "$SCRIPT_DIR/config"
set +o allexport
CACHE_FILE="$HOME/.cache/old_quote.txt"
MAX_LENGTH=150
WRAP_WIDTH=40
CURL_CMD="curl -s --max-time 5 -k"
WGET_CMD="wget -qnvO- -T 5 --no-check-certificate"
fetch_data() {
local url="$1"
($CURL_CMD "$url" || $WGET_CMD "$url")
}
get_quote() {
local source_type="$1"
local API_URL=""
local jq_filter=""
local raw_data=""
case "$source_type" in
"BRAINYQUOTE")
API_URL="http://www.brainyquote.com/link/quotebr.js"
raw_data=$(fetch_data "$API_URL" 2>/dev/null)
if [[ -n "$raw_data" ]]; then
echo "$raw_data" | sed -n 's/.*innerHTML="\([^"]*\)".*/\1/p' | sed 's/<[^>]*>//g'
fi
return 0
;;
"RANDOMQUOTE")
API_URL="https://random-quotes-freeapi.vercel.app/api/random"
jq_filter='.quote'
;;
"QUOTABLE")
API_URL="https://api.quotable.io/random"
jq_filter='.content'
;;
*)
API_URL="https://zenquotes.io/api/random"
jq_filter='.[0].q'
;;
esac
if [[ -n "$API_URL" ]]; then
raw_data=$(fetch_data "$API_URL" 2>/dev/null)
if [[ -n "$raw_data" ]]; then
echo "$raw_data" | jq -r "$jq_filter" 2>/dev/null
fi
fi
return 0
}
QUOTE_SOURCE_ACTUAL="$QUOTE_SOURCE"
if [[ "$QUOTE_SOURCE" == "ROUNDROBIN" ]]; then
LAST_SOURCE=$(head -n 1 "$CACHE_FILE" 2>/dev/null)
case "$LAST_SOURCE" in
"BRAINYQUOTE") QUOTE_SOURCE_ACTUAL="RANDOMQUOTE" ;;
"RANDOMQUOTE") QUOTE_SOURCE_ACTUAL="ZENQUOTES" ;;
"ZENQUOTES") QUOTE_SOURCE_ACTUAL="QUOTABLE" ;;
*) QUOTE_SOURCE_ACTUAL="BRAINYQUOTE" ;;
esac
fi
RAW_QUOTE=$(get_quote "$QUOTE_SOURCE_ACTUAL")
TRANSLATED_QUOTE=""
if [[ -n "$RAW_QUOTE" ]]; then
TRANSLATED_QUOTE=$(echo "$RAW_QUOTE" | trans -brief :"$LANG" 2>/dev/null)
if [[ -z "$TRANSLATED_QUOTE" ]]; then
TRANSLATED_QUOTE="$RAW_QUOTE"
fi
fi
if [[ -n "$TRANSLATED_QUOTE" ]]; then
if (( ${#TRANSLATED_QUOTE} <= MAX_LENGTH )); then
echo -e "$QUOTE_SOURCE_ACTUAL\n$TRANSLATED_QUOTE" > "$CACHE_FILE"
echo "$TRANSLATED_QUOTE" | fmt -${WRAP_WIDTH}
else
tail -n 1 "$CACHE_FILE" 2>/dev/null | fmt -${WRAP_WIDTH}
fi
else
OLD_QUOTE_TEXT=$(tail -n 1 "$CACHE_FILE" 2>/dev/null)
if [[ "$QUOTE_SOURCE" == "ROUNDROBIN" ]]; then
echo -e "$QUOTE_SOURCE_ACTUAL\n$OLD_QUOTE_TEXT" > "$CACHE_FILE"
fi
echo "$OLD_QUOTE_TEXT" | fmt -${WRAP_WIDTH}
fi
exit 0
