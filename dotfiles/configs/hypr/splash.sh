#!/usr/bin/env bash
QUOTES="$HOME/.config/hypr/borges_splash.txt"
QUOTE=$(shuf -n 1 "$QUOTES")
echo "misc { splash_str = \"$QUOTE\" }" > "$HOME/.config/hypr/current_splash.conf"
