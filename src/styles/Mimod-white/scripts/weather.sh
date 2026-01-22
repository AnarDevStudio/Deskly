#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
set -o allexport
source "$SCRIPT_DIR/config"
set +o allexport
CACHE_FILE="$HOME/.cache/weather.json"
TEMP_FILE="${CACHE_FILE}.tmp"
CACHE_EXPIRATION=600
API_URL_BASE="http://api.openweathermap.org/data/2.5/weather?appid=$API_KEY"
CURL_CMD="curl -s --max-time 5 -k"
WGET_CMD="wget -qnvO- -T 5 --no-check-certificate"
start_geoclue_agent() {
local AGENT_PATH="/usr/lib/geoclue-2.0/demos/agent"
if [[ -x "$AGENT_PATH" ]] && ! pgrep -f "$AGENT_PATH" > /dev/null; then
"$AGENT_PATH" &
sleep 1
fi
}
GEOCLUE_CMD=""
for path in "/usr/libexec/geoclue-2.0/demos/where-am-i" "/usr/lib/geoclue-2.0/demos/where-am-i" "/usr/bin/where-am-i"; do
if [[ -x "$path" ]]; then
GEOCLUE_CMD="$path"
break
fi
done
if [[ -n "$GEOCLUE_CMD" ]]; then
start_geoclue_agent
fi
update_config() {
local key="$1"
local value="$2"
local config_file="$HOME/.config/conky/Mimod-white/scripts/config"
sed -i "s/^\(${key}=\).*$/\1\"${value}\"/" "$config_file"
}
declare -A LANG_MAP=(
["DE"]="de" ["AT"]="de" ["CH"]="de" ["LI"]="de"
["FR"]="fr" ["BE"]="fr" ["LU"]="fr" ["CA"]="fr"
["IT"]="it" ["SM"]="it" ["VA"]="it"
["ES"]="es" ["MX"]="es" ["AR"]="ar" ["CO"]="es" ["CL"]="es" ["PE"]="es"
["PL"]="pl" ["CZ"]="cz" ["SK"]="sk" ["HU"]="hu" ["RO"]="ro"
["RU"]="ru" ["UA"]="ru" ["BY"]="ru"
["CN"]="zh_cn" ["TW"]="zh_tw" ["HK"]="zh_tw"
["JP"]="ja" ["KR"]="kr"
["BD"]="bn" ["IN"]="hi"
["TR"]="tr" ["PT"]="pt" ["BR"]="pt"
["NL"]="nl" ["SE"]="sv" ["NO"]="no" ["DK"]="da" ["FI"]="fi"
["GR"]="el" ["EG"]="ar" ["SA"]="ar"
["IL"]="he" ["VN"]="vi" ["TH"]="th" ["ID"]="id"
)
determine_locale() {
local country="$1"
if [[ -z "$LANG" || "$LANG" == "en" ]]; then
UNIT="metric"
LANG="en"
[[ -n "${LANG_MAP[$country]}" ]] && LANG="${LANG_MAP[$country]}"
[[ "$country" == "US" ]] && UNIT="imperial"
fi
export UNIT LANG
}
fetch_data() {
local url="$1"
($CURL_CMD "$url" || $WGET_CMD "$url")
}
get_location_and_config() {
local LAT="" LON="" COUNTRY=""
if [[ -n "$GEOCLUE_CMD" ]]; then
local GEOCLUE_DATA=$("$GEOCLUE_CMD" --timeout=5 2>/dev/null)
if [[ -n "$GEOCLUE_DATA" ]]; then
LAT=$(echo "$GEOCLUE_DATA" | grep "Latitude:" | cut -d: -f2 | tr -d '[:space:]' | sed 's/[^0-9.-]//g')
LON=$(echo "$GEOCLUE_DATA" | grep "Longitude:" | cut -d: -f2 | tr -d '[:space:]' | sed 's/[^0-9.-]//g' | sed 's/\.$//')
fi
fi
if [[ -z "$LAT" || "$LAT" == "null" ]]; then
local GEO_PROVIDERS=(
"https://ipapi.co/json|.latitude|.longitude|.country_code"
"https://freeipapi.com/api/json|.latitude|.longitude|.countryCode"
"http://ip-api.com/json|.lat|.lon|.countryCode"
"https://ipinfo.io/json|.loc|.country"
)
for provider_entry in "${GEO_PROVIDERS[@]}"; do
IFS='|' read -r provider_url LAT_PATH COUNTRY_PATH <<< "$provider_entry"
local GEO_DATA=$($CURL_CMD "$provider_url")
if [[ -n "$GEO_DATA" ]]; then
if [[ "$LAT_PATH" == ".loc" ]]; then
local LOC=$(echo "$GEO_DATA" | jq -r '.loc' 2>/dev/null)
COUNTRY=$(echo "$GEO_DATA" | jq -r '.country' 2>/dev/null)
if [[ "$LOC" =~ ^([0-9.-]+),([0-9.-]+)$ ]]; then
LAT=${BASH_REMATCH[1]}
LON=${BASH_REMATCH[2]}
fi
else
LAT=$(echo "$GEO_DATA" | jq -r "$LAT_PATH" 2>/dev/null)
LON=$(echo "$GEO_DATA" | jq -r "${LAT_PATH/.latitude/.longitude}" 2>/dev/null)
COUNTRY=$(echo "$GEO_DATA" | jq -r "$COUNTRY_PATH" 2>/dev/null)
fi
if [[ -n "$LAT" && "$LAT" != "null" && "$LAT" != "" && "$LAT" =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
break
else
LAT="" LON="" COUNTRY=""
fi
fi
done
fi
if [[ -n "$LAT" && "$LAT" != "null" ]]; then
local GEO_API_URL="${API_URL_BASE}&lat=$LAT&lon=$LON"
if fetch_data "$GEO_API_URL" > "$TEMP_FILE"; then
local CITY_ID_LOCAL=$(jq -r '.id' "$TEMP_FILE" 2>/dev/null)
COUNTRY=$(jq -r '.sys.country' "$TEMP_FILE" 2>/dev/null)
if [[ -n "$CITY_ID_LOCAL" && "$CITY_ID_LOCAL" != "null" && -n "$COUNTRY" && "$COUNTRY" != "null" ]]; then
determine_locale "$COUNTRY"
update_config "CITY_ID" "$CITY_ID_LOCAL"
update_config "UNIT" "$UNIT"
update_config "LANG" "$LANG"
export CITY_ID="$CITY_ID_LOCAL"
return 0
fi
fi
fi
return 1
}
if [[ -z "$CITY_ID" ]]; then
get_location_and_config
fi
if [[ -z "$CITY_ID" ]] && [[ ! -f "$CACHE_FILE" ]]; then
exit 0
fi
API_URL="${API_URL_BASE}&id=$CITY_ID&units=$UNIT&lang=$LANG"
if [[ ! -f "$CACHE_FILE" ]] || (( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null) > CACHE_EXPIRATION )); then
if fetch_data "$API_URL" > "$TEMP_FILE"; then
if [[ -s "$TEMP_FILE" ]]; then
if ! grep -q '"cod":[4-5][0-9][0-9]' "$TEMP_FILE"; then
mv "$TEMP_FILE" "$CACHE_FILE"
else
rm "$TEMP_FILE"
fi
fi
fi
fi
exit 0
