#!/bin/bash
kitty \
  --title "keybinds" \
  --override initial_window_width=600 \
  --override initial_window_height=520 \
  --override background_opacity=0.95 \
  -e bat --style=plain --color=always --theme=TwoDark --paging=always \
  ~/.config/hypr/keybinds.txt
