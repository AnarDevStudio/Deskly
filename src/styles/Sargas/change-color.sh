#!/usr/bin/env bash

# Sargas Color Changer v2.6
# by Closebox73

# This script changes the color of circle.png in the Sargas theme
# using hex color codes (e.g., 00bfff, ff9900).
# Invalid or malformed hex codes may result in a black or transparent circle.

# Delay for smoother feedback
sleep 0.5s

# Optional title with figlet if available
if command -v figlet &>/dev/null; then
    figlet -t "Sargas"
    echo "Accent color changer script"
else
    echo "Sargas color changer"
fi
sleep 1s
echo
echo "This script uses hex color codes (without #)."
echo "Example: 00bfff for DeepSkyBlue or ffcc00 for warm yellow."
echo

# Validate input
if [ -z "$1" ]; then
    echo "Error: No hex color code provided."
    echo "Usage: $0 [HexColorWithoutHash]"
    echo "Example: $0 00bfff"
    exit 1
fi

COLOR_NAME="$1"

sleep 1s
echo "Processing....."
sleep 2s

echo "Stoping Sargas"
killall conky

sleep 0.7s
echo "Set up Accent"
sed -i "34s|color1 = .*|color1 = '${COLOR_NAME}',|" ~/.config/conky/Sargas/Sargas.conf &

sleep 0.7s
echo "Changing system ring colors..."
sleep 0.2s
sed -i "17s|fg_color = 0x.*|fg_color = 0x${COLOR_NAME},|" ~/.config/conky/Sargas/lib/rings_rounded.lua &
sleep 0.2s
sed -i "32s|fg_color = 0x.*|fg_color = 0x${COLOR_NAME},|" ~/.config/conky/Sargas/lib/rings_rounded.lua &
sleep 0.2s
sed -i "47s|fg_color = 0x.*|fg_color = 0x${COLOR_NAME},|" ~/.config/conky/Sargas/lib/rings_rounded.lua &
sleep 0.2s
sed -i "62s|fg_color = 0x.*|fg_color = 0x${COLOR_NAME},|" ~/.config/conky/Sargas/lib/rings_rounded.lua &

sleep 1s
echo "Restarting Sargas Conky..."
"$HOME/.config/conky/Sargas/start.sh" &>/dev/null &

sleep 3s
echo "Done."

exit 0
