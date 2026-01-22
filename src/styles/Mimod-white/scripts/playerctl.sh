#!/bin/bash
output() {
local text="$1"
local max_length="$2"
if (( ${#text} > max_length )); then
echo "${text:0:$max_length}..."
else
echo "$text"
fi
}
url_safe_encode() {
local encoded="${1}"
encoded="${encoded//&/%26}"
encoded="${encoded//+/%2B}"
encoded="${encoded//\#/%23}"
encoded="${encoded// /%20}"
echo "${encoded}"
}
get_user_agent() {
echo "Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.7444.172 Mobile Safari/537.36"
}
METADATA=$(playerctl metadata --format "{{xesam:artist}}|{{xesam:title}}" 2>/dev/null)
METADATA_CLEANED="${METADATA//[$'\n'$'\r']/}"
METADATA_CLEANED="${METADATA_CLEANED#"${METADATA_CLEANED%%[![:space:]]*}"}"
METADATA_CLEANED="${METADATA_CLEANED%"${METADATA_CLEANED##*[![:space:]]}"}"
IFS='|' read -r ARTIST TITLE <<< "$METADATA_CLEANED"
handle_fallback() {
local field="$1"
local fallback="$2"
local max_length="$3"
if [[ -z "$field" ]]; then
output "$fallback" "$max_length"
else
output "$field" "$max_length"
fi
}
TEMP_DIR="/dev/shm"
DOWNLOAD_STATIC_LINK="$TEMP_DIR/cover_static.jpg"
TEMP_COVER="$TEMP_DIR/cover_temp_music_script.jpg"
USER_AGENT=$(get_user_agent)
make_cover_round_on_black() {
local input_cover="$1"
local output_cover="$2"
local temp_mask="$TEMP_DIR/round_mask_highres.png"
local temp_transp="$TEMP_DIR/cover_round_transparent_highres.png"
local temp_tinted="$TEMP_DIR/cover_round_tinted.png"
local temp_ring_highres="$TEMP_DIR/cover_ring_highres.png"
magick -size 300x300 xc:transparent -fill white -draw "circle 150,150 290,150" "$temp_mask"
magick "$input_cover" -resize 300x300! "$temp_mask" -alpha Off -compose CopyOpacity -composite "$temp_transp"
magick "$temp_transp" \( -clone 0 -fill 'rgba(0,0,0,0.6)' -draw 'color 0,0 reset' \) -compose DstIn -composite -filter Cubic -resize 75x75! "$temp_tinted"
magick -size 300x300 xc:transparent -strokewidth 8 -stroke "#999999" -fill transparent -draw "circle 150,150 295,150" "$temp_ring_highres"
magick -size 75x75 xc:#2f2f2f "$temp_tinted" -composite "$temp_ring_highres" -resize 75x75! -composite "$output_cover"
rm -f "$temp_mask" "$temp_transp" "$temp_tinted" "$temp_ring_highres"
}
perform_download() {
local cover_url="$1"
local temp_pid_file="$TEMP_COVER.$$"
trap 'rm -f "$temp_pid_file"' EXIT TERM INT HUP
if curl -s -L --fail --max-time 3 -A "$USER_AGENT" -o "$temp_pid_file" "$cover_url"; then
if [[ -f "$temp_pid_file" && -s "$temp_pid_file" ]]; then
mv "$temp_pid_file" "$TEMP_COVER" 2>/dev/null
fi
fi
}
download_musicbrainz_cover() {
local artist="$1"
local title="$2"
local url_artist=$(url_safe_encode "$artist")
local url_title=$(url_safe_encode "$title")
local api_url="https://musicbrainz.org/ws/2/recording/?query=artist:$url_artist%20AND%20recording:$url_title&fmt=json&limit=1&inc=releases"
local mbid=$(curl -s -A "$USER_AGENT" "$api_url" | jq -r '.recordings[0].releases[0].id' 2>/dev/null)
if [[ -n "$mbid" && "$mbid" != "null" ]]; then
local cover_url="https://coverartarchive.org/release/$mbid/front-500"
perform_download "$cover_url"
fi
}
download_itunes_cover() {
local artist="$1"
local title="$2"
local search_query=$(url_safe_encode "$artist $title")
local search_query="${search_query//%20/+}";
local url="https://itunes.apple.com/search?term=$search_query&limit=1&entity=song"
local cover_url=$(curl -s -A "$USER_AGENT" "$url" | jq -r '.results[0].artworkUrl100' 2>/dev/null | sed 's/100x100bb/600x600bb/g')
if [[ -n "$cover_url" && "$cover_url" != "null" ]]; then
perform_download "$cover_url"
fi
}
download_itunes_artist_only() {
local artist="$1"
local search_query=$(url_safe_encode "$artist")
local search_query="${search_query//%20/+}";
local url="https://itunes.apple.com/search?term=$search_query&limit=1&entity=album"
local cover_url=$(curl -s -A "$USER_AGENT" "$url" | jq -r '.results[0].artworkUrl100' 2>/dev/null | sed 's/100x100bb/600x600bb/g')
if [[ -n "$cover_url" && "$cover_url" != "null" ]]; then
perform_download "$cover_url"
fi
}
download_deezer_cover() {
local artist="$1"
local title="$2"
local search_query=$(url_safe_encode "$artist $title")
local url="https://api.deezer.com/search?q=$search_query"
local cover_url=$(curl -s -A "$USER_AGENT" "$url" | jq -r '.data[0].album.cover_big' 2>/dev/null)
if [[ -n "$cover_url" && "$cover_url" != "null" ]]; then
perform_download "$cover_url"
fi
}
download_deezer_artist_only() {
local artist="$1"
local search_query=$(url_safe_encode "$artist")
local url="https://api.deezer.com/search?q=artist:\"$search_query\"&limit=1"
local cover_url=$(curl -s -A "$USER_AGENT" "$url" | jq -r '.data[0].album.cover_big' 2>/dev/null)
if [[ -n "$cover_url" && "$cover_url" != "null" ]]; then
perform_download "$cover_url"
fi
}
download_lastfm_cover() {
local artist="$1"
local title="$2"
local url_artist=$(url_safe_encode "$artist")
local url_title=$(url_safe_encode "$title")
local url="https://www.last.fm/music/$url_artist/$url_title"
local cover_url=$(curl -s -A "$USER_AGENT" "$url" | grep -oP 'https?://[^"]*lastfm\.freetls\.fastly\.net[^"]*?\.jpg' | head -n 1)
if [[ -n "$cover_url" ]]; then
perform_download "$cover_url"
fi
}
download_musicbrainz_release_group_fallback() {
local artist="$1"
local url_artist=$(url_safe_encode "$artist")
local api_url="https://musicbrainz.org/ws/2/release/?query=artist:$url_artist%20AND%20primarytype:Album%20AND%20status:official&fmt=json&limit=1"
local mbid=$(curl -s -A "$USER_AGENT" "$api_url" | jq -r '.releases[0].id' 2>/dev/null)
if [[ -n "$mbid" && "$mbid" != "null" ]]; then
local cover_url="https://coverartarchive.org/release/$mbid/front-500"
perform_download "$cover_url"
fi
}
goto_processing() {
if make_cover_round_on_black "$TEMP_COVER" "$DOWNLOAD_STATIC_LINK"; then
rm -f "$TEMP_COVER"
else
rm -f "$DOWNLOAD_STATIC_LINK"
rm -f "$TEMP_COVER"
fi
rm -f "$TEMP_DIR/cover_temp_music_script.jpg".*
}
download_cover() {
local artist="$1"
local title="$2"
rm -f "$TEMP_COVER" "$TEMP_DIR/cover_temp_music_script.jpg".*
download_deezer_cover "$artist" "$title"
if [[ -f "$TEMP_COVER" ]]; then goto_processing; return 0; fi
download_musicbrainz_cover "$artist" "$title"
if [[ -f "$TEMP_COVER" ]]; then goto_processing; return 0; fi
download_itunes_cover "$artist" "$title"
if [[ -f "$TEMP_COVER" ]]; then goto_processing; return 0; fi
sleep 1
download_lastfm_cover "$artist" "$title"
if [[ -f "$TEMP_COVER" ]]; then goto_processing; return 0; fi
if [[ -z "$TITLE" ]]; then
download_itunes_artist_only "$artist"
if [[ -f "$TEMP_COVER" ]]; then goto_processing; return 0; fi
download_deezer_artist_only "$artist"
if [[ -f "$TEMP_COVER" ]]; then goto_processing; return 0; fi
download_musicbrainz_release_group_fallback "$artist"
if [[ -f "$TEMP_COVER" ]]; then goto_processing; return 0; fi
fi
rm -f "$DOWNLOAD_STATIC_LINK"
rm -f "$TEMP_DIR/cover_temp_music_script.jpg".*
}
test_download_functions() {
local artist="The Beatles"
local title="Abbey Road"
echo "--- TEST: sources '$artist - $title' ---"
local functions=(
"download_musicbrainz_cover"
"download_itunes_cover"
"download_deezer_cover"
"download_lastfm_cover"
"download_itunes_artist_only"
"download_deezer_artist_only"
"download_musicbrainz_release_group_fallback"
)
for func in "${functions[@]}"; do
rm -f "$DOWNLOAD_STATIC_LINK"
rm -f "$TEMP_COVER"
echo -n "Test $func... "
eval "$func \"$artist\" \"$title\""
sleep 2
if [ -f "$TEMP_COVER" ]; then
local size=$(du -h "$TEMP_COVER" | awk '{print $1}')
if make_cover_round_on_black "$TEMP_COVER" "$DOWNLOAD_STATIC_LINK"; then
rm -f "$TEMP_COVER"
rm -f "$DOWNLOAD_STATIC_LINK"
echo "[ok] - got file ($size)"
else
rm -f "$TEMP_COVER"
rm -f "$DOWNLOAD_STATIC_LINK"
echo "[bad] (processing)"
fi
else
echo "[bad] (Download)"
fi
done
echo "--- TEST END ---"
}
process_cover_in_background() {
local artist="$1"
local title="$2"
download_cover "$artist" "$title"
}
output_cover_image() {
if [[ -f "$DOWNLOAD_STATIC_LINK" ]]; then
echo "\${image /dev/shm/cover_static.jpg -p 275,415 -s 75x75}"
fi
}
if [[ "$1" == "test" ]]; then
test_download_functions
exit 0
fi
if [[ -z "$ARTIST" && -z "$TITLE" ]]; then
case $1 in
-a) echo "¯\_(•.°)_/¯" ;;
-t) echo "" ;;
-c)
;;
esac
rm -f "$DOWNLOAD_STATIC_LINK"
rm -f "/dev/shm/current_song_music_script.txt"
else
CACHE_FILE="/dev/shm/current_song_music_script.txt"
case $1 in
-a)
handle_fallback "$ARTIST" "$TITLE" 13
;;
-t)
handle_fallback "$TITLE" "$ARTIST" 22
;;
-c)
output_cover_image
;;
esac
CURRENT_SONG_CACHED=$(cat "$CACHE_FILE" 2>/dev/null)
if [[ "$CURRENT_SONG_CACHED" != "$ARTIST|$TITLE" ]]; then
echo "$ARTIST|$TITLE" > "$CACHE_FILE"
( process_cover_in_background "$ARTIST" "$TITLE" & ) &
fi
fi
exit 0
