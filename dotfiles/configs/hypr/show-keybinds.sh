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
R='\e[0m'; B='\e[1m'

sec() {
    local title="$1"
    local pad=$(( 46 - ${#title} ))
    printf "\n${C}${B}  ╟─ %s ${D}" "$title"
    printf '─%.0s' $(seq 1 $pad)
    printf "${R}\n"
}

kb() {
    printf "  ${K}│${R}  ${G}%-24s${K}·· ${W}%s${R}\n" "$1" "$2"
}

empty() {
    printf "  ${K}│${R}\n"
}

render() {
clear
echo -e "${P}${B}"
cat << 'EOF'
  ╔══════════════════════════════════════════════════╗
  ║                                                  ║
  ║        HYPRLAND  ·  ATAJOS DE TECLADO            ║
  ║                                                  ║
  ╚══════════════════════════════════════════════════╝
EOF
echo -e "${R}"

echo -e "  ${K}╔$(printf '═%.0s' $(seq 1 50))╗${R}"

sec "APLICACIONES"
empty
kb "Super + Q"              "Terminal (Kitty)"
kb "Super + R"              "Launcher (Rofi)"
kb "Super + F"              "Archivos (Yazi)"
kb "Super + E"              "spf"
kb "Super + C"              "Cerrar ventana activa"
empty

sec "VENTANAS"
empty
kb "Super + V"              "Toggle flotante"
kb "Super + ←↑↓→"          "Mover foco entre ventanas"
empty

sec "ESCRITORIOS"
empty
kb "Super + 1-10"           "Ir al escritorio N"
kb "Super + Shift + 1-10"   "Mover ventana al escritorio N"
empty

sec "SISTEMA"
empty
kb "Super + M"              "Salir de Hyprland"
kb "F1"                     "Mostrar este cheatsheet"
empty

echo -e "  ${K}╠$(printf '═%.0s' $(seq 1 50))╣${R}"

sec "NEOVIM — GENERAL"
empty
kb "Space"                  "Leader key"
kb "Space + w"              "Guardar archivo"
kb "Space + q"              "Salir"
kb "jk  (insert)"           "Volver a modo normal"
kb "Ctrl + a"               "Seleccionar todo"
empty

sec "NEOVIM — VENTANAS Y TABS"
empty
kb "Space + sh"             "Split horizontal"
kb "Space + sv"             "Split vertical"
kb "Ctrl + h/j/k/l"         "Navegar splits"
kb "Ctrl + ←↑↓→"           "Redimensionar split"
kb "Tab / Shift+Tab"        "Siguiente / anterior buffer"
kb "Space + x"              "Cerrar buffer"
kb "Alt + p"                "Pinear buffer"
empty

sec "NEOVIM — ARCHIVOS"
empty
kb "Space + Space"          "Buscar archivos (smart)"
kb "Space + ff"             "Buscar archivos"
kb "Space + fr"             "Archivos recientes"
kb "Space + fg"             "Archivos git"
kb "Space + /"              "Buscar texto (grep)"
kb "Space + e"              "Explorador"
kb "Space + ,"              "Buffers abiertos"
empty

sec "NEOVIM — GIT"
empty
kb "Space + gs"             "Git status"
kb "Space + gl"             "Git log"
kb "Space + gb"             "Git branches"
kb "Space + gd"             "Git diff"
empty

sec "NEOVIM — LSP"
empty
kb "K"                      "Ver documentación"
kb "gd"                     "Ir a definición"
kb "gr"                     "Ver referencias"
kb "Space + ca"             "Code action"
kb "Space + ss"             "Símbolos LSP"
empty

echo -e "  ${K}╠$(printf '═%.0s' $(seq 1 50))╣${R}"

sec "YAZI — NAVEGACIÓN"
empty
kb "h / l"                  "Salir / entrar carpeta"
kb "j / k"                  "Bajar / subir"
kb "Enter"                  "Abrir archivo"
kb "q"                      "Salir"
empty

sec "YAZI — OPERACIONES"
empty
kb "y / x / p"              "Copiar / Cortar / Pegar"
kb "d / D"                  "Papelera / Borrar permanente"
kb "r"                      "Renombrar"
kb "a"                      "Crear archivo/carpeta  (/ = carpeta)"
kb "Space / v / V"          "Seleccionar / Visual / Todo"
kb "f / F"                  "Buscar / Buscar recursivo"
kb "."                      "Mostrar/ocultar ocultos"
kb "z"                      "Saltar con zoxide"
empty

echo -e "  ${K}╚$(printf '═%.0s' $(seq 1 50))╝${R}\n"
}

render | less -R --no-init --quit-if-one-screen
