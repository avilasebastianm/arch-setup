#!/bin/bash

# ── Colores Dracula true-color ──────────────────────────────────────────────
P='\e[38;2;189;147;249m'   # purple  #bd93f9
G='\e[38;2;80;250;123m'    # green   #50fa7b
W='\e[38;2;248;248;242m'   # white   #f8f8f2
C='\e[38;2;139;233;253m'   # cyan    #8be9fd
Y='\e[38;2;241;250;140m'   # yellow  #f1fa8c
D='\e[38;2;98;114;164m'    # dim     #6272a4
K='\e[38;2;68;71;90m'      # dark    #44475a
PK='\e[38;2;255;121;198m'  # pink    #ff79c6
O='\e[38;2;255;184;108m'   # orange  #ffb86c
R='\e[0m'; B='\e[1m'

CW=34          # ancho de contenido por columna
PAD=2          # padding interno (izq y der)
SLOT=$(( CW + PAD * 2 ))                                           # = 38
TABLE_W=$(( 1 + SLOT + 1 + SLOT + 1 + SLOT + 1 ))                 # = 118
TITLE="HYPRLAND  ·  ATAJOS DE TECLADO"

# Auto-centrar en la terminal
TERM_W=$(tput cols)
LEFT=$(( (TERM_W - TABLE_W) / 2 ))
(( LEFT < 0 )) && LEFT=0
IND=$(printf '%*s' $LEFT '')
PAD_S=$(printf '%*s' $PAD '')
DSLOT=$(printf '─%.0s' $(seq 1 $SLOT))

hdr() {
    local color="$1" title="$2"
    local prefix=" $title "
    local dashes=$(( CW - ${#prefix} ))
    (( dashes < 0 )) && dashes=0
    printf "${color}${B}%s%s${R}" "$prefix" "$(printf '─%.0s' $(seq 1 $dashes))"
}

row() {
    printf "${G}%-14s${D}··${W}%-*s${R}" "$1" $(( CW - 16 )) "$2"
}

sep() { printf '%*s' $CW ''; }

# ── Columnas ─────────────────────────────────────────────────────────────────
declare -a COL1 COL2 COL3
c1() { COL1+=("$1"); }
c2() { COL2+=("$1"); }
c3() { COL3+=("$1"); }

# HYPRLAND
c1 "$(hdr "$P" 'HYPRLAND')"
c1 "$(sep)"
c1 "$(hdr "$C" 'Apps')"
c1 "$(row 'Super+Q'        'Terminal (Kitty)')"
c1 "$(row 'Super+R'        'Launcher (Rofi)')"
c1 "$(row 'Super+F'        'Yazi / Fullscreen')"
c1 "$(row 'Super+E'        'spf')"
c1 "$(row 'Super+C'        'Cerrar ventana')"
c1 "$(row 'F1'             'Este cheatsheet')"
c1 "$(sep)"
c1 "$(hdr "$C" 'Ventanas')"
c1 "$(row 'Super+V'        'Toggle flotante')"
c1 "$(row 'Super+Flechas'  'Mover foco')"
c1 "$(row 'Super+M'        'Salir Hyprland')"
c1 "$(sep)"
c1 "$(hdr "$C" 'Escritorios')"
c1 "$(row 'Super+1-10'     'Ir a escritorio N')"
c1 "$(row 'Super+Shift+N'  'Mover ventana')"
c1 "$(row 'Super+S'        'Scratchpad')"
c1 "$(sep)"
c1 "$(hdr "$C" 'Media')"
c1 "$(row 'F2 / F3'        'Vol - / +')"
c1 "$(row 'F4'             'Mute')"
c1 "$(row 'F5 / F6'        'Brillo - / +')"
c1 "$(row 'Prev/Play/Next' 'Playerctl')"
c1 "$(sep)"
c1 "$(hdr "$C" 'Capturas')"
c1 "$(row 'PrtSc'          'Area (slurp)')"
c1 "$(row 'Super+PrtSc'    'Pantalla completa')"
c1 "$(row 'Sup+Shift+PrtSc' 'Ventana activa')"

# NEOVIM
c2 "$(hdr "$O" 'NEOVIM')"
c2 "$(sep)"
c2 "$(hdr "$Y" 'General')"
c2 "$(row 'Space'          'Leader key')"
c2 "$(row 'Space+w'        'Guardar')"
c2 "$(row 'Space+q'        'Salir')"
c2 "$(row 'jk  (insert)'   'Modo normal')"
c2 "$(row 'Ctrl+a'         'Seleccionar todo')"
c2 "$(sep)"
c2 "$(hdr "$Y" 'Ventanas & Tabs')"
c2 "$(row 'Space+sh'       'Split horizontal')"
c2 "$(row 'Space+sv'       'Split vertical')"
c2 "$(row 'Ctrl+h/j/k/l'   'Navegar splits')"
c2 "$(row 'Ctrl+Flechas'   'Redimensionar')"
c2 "$(row 'Tab / Shift+Tab' 'Sig / ant buffer')"
c2 "$(row 'Space+x'        'Cerrar buffer')"
c2 "$(row 'Alt+p'          'Pinear buffer')"
c2 "$(sep)"
c2 "$(hdr "$Y" 'Archivos')"
c2 "$(row 'Space+Space'    'Buscar (smart)')"
c2 "$(row 'Space+ff'       'Buscar archivos')"
c2 "$(row 'Space+fr'       'Recientes')"
c2 "$(row 'Space+/'        'Grep texto')"
c2 "$(row 'Space+e'        'Explorador')"
c2 "$(row 'Space+,'        'Buffers abiertos')"
c2 "$(sep)"
c2 "$(hdr "$Y" 'Git')"
c2 "$(row 'Space+gs'       'Status')"
c2 "$(row 'Space+gl'       'Log')"
c2 "$(row 'Space+gb'       'Branches')"
c2 "$(row 'Space+gd'       'Diff')"
c2 "$(sep)"
c2 "$(hdr "$Y" 'LSP')"
c2 "$(row 'K'              'Documentacion')"
c2 "$(row 'gd'             'Ir a definicion')"
c2 "$(row 'gr'             'Referencias')"
c2 "$(row 'Space+ca'       'Code action')"
c2 "$(row 'Space+ss'       'Simbolos LSP')"

# YAZI
c3 "$(hdr "$G" 'YAZI')"
c3 "$(sep)"
c3 "$(hdr "$PK" 'Navegacion')"
c3 "$(row 'h / l'          'Salir / entrar dir')"
c3 "$(row 'j / k'          'Bajar / subir')"
c3 "$(row 'Enter'          'Abrir archivo')"
c3 "$(row 'q'              'Salir')"
c3 "$(row 'g'              'Ir a ruta')"
c3 "$(row 'z'              'Saltar (zoxide)')"
c3 "$(sep)"
c3 "$(hdr "$PK" 'Operaciones')"
c3 "$(row 'y / x / p'      'Copiar/Cortar/Pegar')"
c3 "$(row 'd / D'          'Papelera / Borrar')"
c3 "$(row 'r'              'Renombrar')"
c3 "$(row 'a'              'Crear  (/ = dir)')"
c3 "$(sep)"
c3 "$(hdr "$PK" 'Seleccion')"
c3 "$(row 'Space'          'Seleccionar item')"
c3 "$(row 'v / V'          'Visual / Todo')"
c3 "$(row 'f / F'          'Buscar / Recursivo')"
c3 "$(row '.'              'Mostrar ocultos')"
c3 "$(sep)"
c3 "$(hdr "$PK" 'Shell & Extra')"
c3 "$(row '!'              'Shell interactivo')"
c3 "$(row 'o'              'Abrir con...')"
c3 "$(row 'c'              'Cambiar CWD')"
c3 "$(row 'Ctrl+s'         'Shell en dir')"

# ── Render ────────────────────────────────────────────────────────────────────
render() {
    clear

    # Título centrado con el ancho de la tabla
    local inner=$(( TABLE_W - 2 ))
    local tlen=${#TITLE}
    local tpad=$(( (inner - tlen) / 2 ))
    local tpad_r=$(( inner - tlen - tpad ))
    printf "${IND}${P}${B}╔%s╗${R}\n" "$(printf '═%.0s' $(seq 1 $inner))"
    printf "${IND}${P}${B}║%*s%s%*s║${R}\n" $tpad '' "$TITLE" $tpad_r ''
    printf "${IND}${P}${B}╚%s╝${R}\n\n" "$(printf '═%.0s' $(seq 1 $inner))"

    # Borde superior de columnas
    printf "${IND}${K}┌%s┬%s┬%s┐${R}\n" "$DSLOT" "$DSLOT" "$DSLOT"

    local max=${#COL1[@]}
    (( ${#COL2[@]} > max )) && max=${#COL2[@]}
    (( ${#COL3[@]} > max )) && max=${#COL3[@]}

    for (( i=0; i<max; i++ )); do
        local l1="${COL1[$i]:-}" l2="${COL2[$i]:-}" l3="${COL3[$i]:-}"

        local v1 v2 v3
        v1=$(printf '%s' "$l1" | sed 's/\x1b\[[0-9;]*m//g')
        v2=$(printf '%s' "$l2" | sed 's/\x1b\[[0-9;]*m//g')
        v3=$(printf '%s' "$l3" | sed 's/\x1b\[[0-9;]*m//g')

        local p1=$(( CW - ${#v1} )); (( p1 < 0 )) && p1=0
        local p2=$(( CW - ${#v2} )); (( p2 < 0 )) && p2=0
        local p3=$(( CW - ${#v3} )); (( p3 < 0 )) && p3=0

        printf "${IND}${K}│${R}%s%s%*s%s${K}│${R}%s%s%*s%s${K}│${R}%s%s%*s%s${K}│${R}\n" \
            "$PAD_S" "$l1" $p1 '' "$PAD_S" \
            "$PAD_S" "$l2" $p2 '' "$PAD_S" \
            "$PAD_S" "$l3" $p3 '' "$PAD_S"
    done

    printf "${IND}${K}└%s┴%s┴%s┘${R}\n\n" "$DSLOT" "$DSLOT" "$DSLOT"
}

render
printf "${IND}${D}Presiona cualquier tecla para cerrar...${R}\n"
read -rn1
