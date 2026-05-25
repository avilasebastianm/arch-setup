#!/usr/bin/env bash
# dunst script hook: reemplaza el ícono de cada notificación con un dibujo al azar.
# Args: $1=appname $2=summary $3=body $4=icon $5=urgency

APPNAME="$1"
SUMMARY="$2"
BODY="$3"
ICON="$4"
URGENCY="$5"

# Guard: el ícono ya es uno nuestro → no procesar (evita loop infinito)
[[ "$ICON" == */dunst/icons/* ]] && exit 0

ICONS_DIR="$HOME/.config/dunst/icons"
mapfile -t ICONS < <(ls "$ICONS_DIR"/art_*.png "$ICONS_DIR"/skull*.png 2>/dev/null)
[[ ${#ICONS[@]} -eq 0 ]] && exit 0

CHOSEN="${ICONS[$RANDOM % ${#ICONS[@]}]}"

# Pequeña pausa para que dunst registre la notificación antes de cerrarla
sleep 0.15
dunstctl close

# Urgencia: dunst pasa LOW/NORMAL/CRITICAL, notify-send necesita minúscula
URG_LOWER="${URGENCY,,}"
# Fallback por si dunst envía en minúscula o número
case "$URG_LOWER" in
    low|0)    URG_LOWER="low" ;;
    normal|1) URG_LOWER="normal" ;;
    critical|2) URG_LOWER="critical" ;;
    *) URG_LOWER="normal" ;;
esac

notify-send \
    --app-name="$APPNAME" \
    --urgency="$URG_LOWER" \
    --icon="$CHOSEN" \
    -- "$SUMMARY" "$BODY"
