#!/usr/bin/env bash

if hyprctl monitors -j | jq -e '[.[] | select(.name | startswith("HEADLESS"))] | length > 0' >/dev/null; then
    ipad-display-off.sh
else
    ipad-display-on.sh
fi
