#!/usr/bin/env bash

pkill -x wayvnc 2>/dev/null

hyprctl monitors -j | jq -r '.[] | select(.name | startswith("HEADLESS")) | .name' | while read -r mon; do
    hyprctl output remove "$mon"
done

notify-send "iPad Display" "Desactivado" 2>/dev/null || true
