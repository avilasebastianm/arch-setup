#!/usr/bin/env bash
# Prueba del módulo netpulse SIN tocar la red ni usar sudo: simula latencia y pérdida.
# Recorre fases (normal → lenta → pérdida → corte) y al salir borra la simulación.
SIM="${XDG_RUNTIME_DIR:-/tmp}/netpulse-sim"
trap 'rm -f "$SIM"; echo; echo "✔ Simulación apagada"' EXIT INT TERM

phase() { echo "▶ $3 ($1 s)"; echo "$2" > "$SIM"; sleep "$1"; }

phase 12 "lat=25 loss=0"    "Normal: rápido, verde"
phase 40 "lat=400 loss=0"   "Lenta (400 ms): el paquete debe ir mucho más despacio"
phase 40 "lat=40 loss=50"   "Pérdida 50%: paquetes rotos, módulo en rojo"
phase 20 "lat=40 loss=100"  "Corte total: todos se rompen"
phase 15 "lat=25 loss=0"    "Vuelve a la normalidad"
