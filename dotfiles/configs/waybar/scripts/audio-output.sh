#!/usr/bin/env bash
# Selector de salida de audio para Waybar
# Detecta automáticamente dispositivos disponibles: no requiere configuración manual.
#
# Lógica:
#   - Tarjeta PCI con parlantes (built-in)  → ofrece HDMI (si hay monitor) + Analógico
#   - Tarjeta PCI sin parlantes (GPU)       → ofrece HDMI solo si hay monitor conectado
#   - Tarjetas USB (headsets, DACs)         → se muestran directamente
#
# Dependencias: pactl, wpctl, rofi

MENU=()     # etiquetas para Rofi
TARGETS=()  # sink name o token interno (BUILTIN_HDMI / BUILTIN_ANALOG)

add_item() { MENU+=("$1"); TARGETS+=("$2"); }

# ─── Parsear todos los cards de audio ─────────────────────────────────────────
# Formato: card_name|bus|alsa_idx|has_speaker|has_hdmi
mapfile -t CARDS < <(pactl list cards | awk '
function emit() {
    if (name != "") print name "|" bus "|" alsa_idx "|" has_spk "|" has_hdmi
    name=""; bus="pci"; alsa_idx=""; has_spk=0; has_hdmi=0
}
/^\s*Name:/             { emit(); name=$2 }
/device\.bus = /        { match($0, /"([^"]+)"/, a); bus = a[1] }
/alsa\.card = /         { match($0, /"([0-9]+)"/, a); alsa_idx = a[1] }
/analog-output-speaker/ { has_spk = 1 }
/hdmi-output-[0-9]+:/   { has_hdmi = 1 }
END                     { emit() }
')

# ─── Parsear todos los sinks (para USB y GPUs) ────────────────────────────────
# Formato: sink_name|label
mapfile -t SINKS < <(pactl list sinks | awk '
function emit() {
    if (name == "") return
    label = (nick != "" && nick != desc) ? desc " (" nick ")" : desc
    print name "|" label
    name=""; nick=""; desc=""
}
/^\s*Name:/               { emit(); name=$2 }
/node\.nick = /           { match($0, /"([^"]+)"/, a); nick = a[1] }
/device\.description = /  { match($0, /"([^"]+)"/, a); desc = a[1] }
END                       { emit() }
')

# Devuelve los sinks pertenecientes a un card dado su nombre
sinks_of_card() {
    local fragment="${1/alsa_card./}"   # pci-0000_00_1f.3 / usb-046d_...
    for s in "${SINKS[@]}"; do
        [[ "${s%%|*}" == *"$fragment"* ]] && echo "$s"
    done
}

# Devuelve el nombre del monitor conectado por HDMI al card ALSA indicado (via ELD)
hdmi_monitor_name() {
    grep -rh "monitor_name" /proc/asound/card${1}/eld* 2>/dev/null \
        | sed 's/.*monitor_name[[:space:]]*//' | head -1
}

# ─── Construir el menú ────────────────────────────────────────────────────────
BUILTIN_CARD=""

for entry in "${CARDS[@]}"; do
    IFS='|' read -r card_name bus alsa_idx has_spk has_hdmi <<< "$entry"

    # — Dispositivos USB (headsets, DACs, etc.) —
    if [[ "$bus" == "usb" ]]; then
        while IFS='|' read -r sink_name label; do
            add_item "$label" "$sink_name"
        done < <(sinks_of_card "$card_name")
        continue
    fi

    # — Tarjeta built-in: PCI con puerto de parlantes —
    if [[ "$has_spk" == "1" ]]; then
        BUILTIN_CARD="$card_name"
        BUILTIN_ALSA="$alsa_idx"
        BUILTIN_HDMI_SINK="${card_name/alsa_card./alsa_output.}.hdmi-stereo"
        BUILTIN_ANALOG_SINK="${card_name/alsa_card./alsa_output.}.analog-stereo"

        MON=$(hdmi_monitor_name "$alsa_idx")
        [[ -n "$MON" ]] && add_item "Monitor HDMI ($MON)" "BUILTIN_HDMI"

        add_item "Parlantes / Auriculares Jack" "BUILTIN_ANALOG"
        continue
    fi

    # — GPU u otro card PCI con HDMI: mostrar solo si hay monitor conectado —
    if [[ "$has_hdmi" == "1" ]]; then
        MON=$(hdmi_monitor_name "$alsa_idx")
        [[ -z "$MON" ]] && continue

        while IFS='|' read -r sink_name label; do
            add_item "GPU HDMI ($MON) — $label" "$sink_name"
        done < <(sinks_of_card "$card_name")
    fi
done

# ─── Mostrar en Rofi ──────────────────────────────────────────────────────────
[[ ${#MENU[@]} -eq 0 ]] && { notify-send "Audio" "No se encontraron salidas de audio" 2>/dev/null; exit 1; }

CHOSEN=$(printf '%s\n' "${MENU[@]}" | rofi -dmenu -p "🔊 Salida de audio")
[[ -z "$CHOSEN" ]] && exit 0

TARGET=""
for i in "${!MENU[@]}"; do
    [[ "${MENU[$i]}" == "$CHOSEN" ]] && TARGET="${TARGETS[$i]}" && break
done
[[ -z "$TARGET" ]] && exit 0

# ─── Aplicar selección ────────────────────────────────────────────────────────
switch_to() {
    local sink="$1"
    pactl set-default-sink "$sink"
    pactl list short sink-inputs | awk '{print $1}' \
        | xargs -I{} pactl move-sink-input {} "$sink" 2>/dev/null
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.30
}

case "$TARGET" in
    BUILTIN_HDMI)
        pactl set-card-profile "$BUILTIN_CARD" output:hdmi-stereo
        sleep 0.5
        switch_to "$BUILTIN_HDMI_SINK"
        ;;
    BUILTIN_ANALOG)
        pactl set-card-profile "$BUILTIN_CARD" output:analog-stereo+input:analog-stereo
        sleep 0.5
        switch_to "$BUILTIN_ANALOG_SINK"
        ;;
    *)
        switch_to "$TARGET"
        ;;
esac
