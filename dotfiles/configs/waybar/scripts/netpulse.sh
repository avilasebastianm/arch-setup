#!/usr/bin/env bash
# Salud de la conexión para Waybar: un paquete viaja de izquierda a derecha (ping) por
# una pista que ocupa el hueco de la barra; si hay respuesta vuelve abierto, y si se
# pierde se rompe en rojo y se desparrama en fragmentos.
# Módulo persistente: imprime un JSON por frame.
# La velocidad del paquete sigue la latencia: más ping = más lento (tramo de 2 s a 30 ms, 6 s tope).
# Cada paquete perdido deja un punto rojo en la pista, que funciona como línea de tiempo de la
# ventana (izquierda = inicio, derecha = próximo reseteo). Al cambiar de ventana (por defecto cada
# 15 min, en :00/:15/:30/:45) los puntos vuelven a gris. No se puede saber si se perdió en la ida o la vuelta.
# Simulación (para probar sin tocar la red): escribir "lat=400 loss=50" (ms y % de pérdida)
# en $XDG_RUNTIME_DIR/netpulse-sim; borrar el archivo la desactiva. Ver netpulse-test.sh.
# Variables: NETPULSE_HOST (default 1.1.1.1), NETPULSE_SLOTS (largo de la pista, default 42),
#            NETPULSE_WINDOW (segundos entre reseteos de los puntos rojos, default 900).
# Dependencias: ping, awk

HOST="${NETPULSE_HOST:-1.1.1.1}"
SLOTS="${NETPULSE_SLOTS:-42}"
STEPS=16          # frames por tramo (ida o vuelta)
LEG_BASE=1.5      # segundos por tramo con latencia ~0
LEG_MAX=6         # tope de segundos por tramo
LEG_MS=60         # cada LEG_MS de latencia suman 1 s al tramo
HISTORY=20        # pings que cuentan para la pérdida
WINDOW="${NETPULSE_WINDOW:-900}"   # segundos entre reseteos de los puntos rojos

SEND=$'\U000f03d7'    # paquete cerrado (va)
REPLY=$'\U000f03d6'   # paquete abierto (vuelve)
DIM='#3b4261'; RED='#f7768e'

SIM="${XDG_RUNTIME_DIR:-/tmp}/netpulse-sim"
TMP=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/netpulse.XXXXXX")
trap 'pkill -P $$ 2>/dev/null; rm -rf "$TMP"; exit' EXIT TERM INT

marks=(); nmarks=0; wid=$(( $(date +%s) / WINDOW ))
hist=(); lat="--"; class="good"; tip="Midiendo conexión…"; loss=0

# track <slot> <glyph> [<slot> <glyph> ...]  → pista con símbolos en esas posiciones
track() {
    local cells=() i out="" run=""
    while [ $# -ge 2 ]; do cells[$1]="$2"; shift 2; done
    for ((i = 0; i < SLOTS; i++)); do
        if [ -n "${cells[$i]}" ] || [ -n "${marks[$i]}" ]; then
            [ -n "$run" ] && { out+="<span color='$DIM'>$run</span>"; run=""; }
            if [ -n "${cells[$i]}" ]; then out+="${cells[$i]}"; else out+="<span color='$RED'>•</span>"; fi
        else
            run+="·"
        fi
    done
    [ -n "$run" ] && out+="<span color='$DIM'>$run</span>"
    printf '%s' "$out"
}

emit() { # emit <texto> [clase]
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$1" "$tip" "${2:-$class}"
}

# Segundos por frame para un tramo, según la latencia (ms) medida
frame_for() {
    awk -v l="${1:-30}" -v s="$STEPS" -v b="$LEG_BASE" -v m="$LEG_MAX" -v d="$LEG_MS" \
        'BEGIN{if(l !~ /^[0-9.]+$/)l=30; t=b+l/d; if(t>m)t=m; printf "%.3f", t/s}'
}

pos() { echo $(( $1 * (SLOTS - 1) / STEPS )); }   # frame k → casilla

health() {
    local n=${#hist[@]} fails=0 v
    for v in "${hist[@]}"; do [ "$v" = 0 ] && fails=$((fails + 1)); done
    loss=$(( n ? fails * 100 / n : 0 ))
    if [ "$loss" -ge 25 ] && [ "$n" -ge 4 ]; then class="bad"
    elif [ "$loss" -gt 0 ] || { [ "$lat" != "--" ] && awk -v l="$lat" 'BEGIN{exit !(l>=100)}'; }; then class="warn"
    else class="good"; fi
    tip="Conexión a $HOST\\nLatencia: ${lat} ms\\nPérdida: ${loss}% (últimos ${#hist[@]} paquetes)\\nPerdidos en esta ventana: ${nmarks} (se reinicia en $(( (WINDOW - $(date +%s) % WINDOW + 59) / 60 )) min)$simtxt"
}

END=$((SLOTS - 1))
while true; do
    now=$(date +%s)
    if [ $((now / WINDOW)) -ne "$wid" ]; then wid=$((now / WINDOW)); marks=(); nmarks=0; fi   # reset: puntos a gris
    rm -f "$TMP/rc" "$TMP/out"
    simtxt=""
    if [ -f "$SIM" ]; then
        sl=$(sed -n 's/.*lat=\([0-9.]*\).*/\1/p' "$SIM"); sp=$(sed -n 's/.*loss=\([0-9]*\).*/\1/p' "$SIM")
        sl=${sl:-30}; sp=${sp:-0}; simtxt="\\n⚠ Modo simulación"
        (
            if [ $((RANDOM % 100)) -lt "$sp" ]; then sleep 2; echo 1 >"$TMP/rc"
            else sleep "$(awk -v l="$sl" 'BEGIN{printf "%.3f", l/1000}')"; echo "time=$sl" >"$TMP/out"; echo 0 >"$TMP/rc"; fi
        ) &
    else
        ( ping -n -c1 -W2 "$HOST" >"$TMP/out" 2>&1; echo $? >"$TMP/rc" ) &
    fi

    # ida (a la velocidad de la última latencia conocida)
    F=$(frame_for "$lat")
    for ((k = 0; k <= STEPS; k++)); do emit "$(track "$(pos $k)" "$SEND")"; sleep "$F"; done

    # esperar el resultado del ping (máx ~2.2 s)
    for ((w = 0; w < 22; w++)); do
        [ -e "$TMP/rc" ] && break
        emit "$(track $END "$SEND")"; sleep 0.1
    done

    push() { hist+=("$1"); [ ${#hist[@]} -gt $HISTORY ] && hist=("${hist[@]:1}"); }

    if [ "$(cat "$TMP/rc" 2>/dev/null)" = "0" ]; then
        lat=$(grep -oP 'time=\K[0-9.]+' "$TMP/out" | head -1); lat=${lat:---}
        push 1; health
        # vuelta (a la velocidad de la latencia recién medida)
        F=$(frame_for "$lat")
        for ((k = STEPS; k >= 0; k--)); do emit "$(track "$(pos $k)" "$REPLY")"; sleep "$F"; done
    else
        push 0
        marks[$(( ($(date +%s) % WINDOW) * (SLOTS - 1) / WINDOW ))]=1; nmarks=$((nmarks + 1))   # punto rojo en su hora
        health
        # paquete roto: tiembla en rojo, se abre y se desparrama
        B="<span color='$RED'>$SEND</span>"; O="<span color='$RED'>$REPLY</span>"
        f1="<span color='$RED'>'</span>"; f2="<span color='$RED'>.</span>"; f3="<span color='$RED'>,</span>"
        emit "$(track $END "$B")" bad;                                  sleep 0.12
        emit "$(track $((END-1)) "$B")" bad;                            sleep 0.12
        emit "$(track $END "$B")" bad;                                  sleep 0.12
        emit "$(track $END "$O")" bad;                                  sleep 0.15
        emit "$(track $END "$O" $((END-1)) "$f1" $((END-3)) "$f2")" bad; sleep 0.15
        emit "$(track $((END-1)) "$f1" $((END-3)) "$f3" $((END-5)) "$f2" $((END-8)) "$f3")" bad; sleep 0.15
        emit "$(track $((END-3)) "$f2" $((END-6)) "$f3" $((END-10)) "$f2")" bad; sleep 0.2
        emit "$(track)" bad;                                            sleep 0.2
    fi

    emit "$(track 0 "$SEND")"; sleep 0.4
done
