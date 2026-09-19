# arch-setup

Instalador y dotfiles personalizados para **Arch Linux + Hyprland**.

```
arch-setup/
├── dotfiles/      # Configs: Hyprland, Waybar, Kitty, Neovim, Dunst, Rofi…
└── arch-install/  # Script de instalación interactivo con soporte dual boot
```

---

## dotfiles

Tema visual basado en **Dracula** para un entorno Wayland completo.

| App | Descripción |
|-----|-------------|
| Hyprland | Compositor Wayland con keybinds y animaciones |
| Waybar | Barra con módulos de audio, red, batería y workspaces |
| Kitty | Terminal con JetBrainsMono Nerd Font |
| Dunst | Notificaciones con iconos pixel art aleatorios |
| Rofi | Launcher y selector de salida de audio |
| Neovim | Editor con configuración personalizada |
| Yazi | File manager en terminal |
| Starship | Prompt minimalista |

### Instalación rápida

```bash
git clone https://github.com/avilasebastianm/arch-setup.git
cd arch-setup/dotfiles
bash install.sh
```

### iPad como monitor extra (opcional)

Podés usar un iPad como segunda pantalla de Hyprland por VNC ([wayvnc](https://github.com/any1/wayvnc)).
El `install.sh` deja los scripts en `~/.local/bin` y `wayvnc` se instala con los paquetes.

1. **Configurá tu usuario y contraseña** (una sola vez). El repo no trae credenciales: el script las pide y genera las claves de tu máquina en `~/.config/wayvnc/`.

   ```bash
   ipad-display-setup.sh
   ```

2. **Activá o desactivá el display** con `Super+Shift+I` o haciendo click en el ícono del iPad en Waybar.
3. **Conectate desde el iPad** con una app VNC (Jump Desktop, bVNC, etc.) a la IP y puerto que muestra la notificación, con el usuario y contraseña del paso 1.

Notas:

- El iPad y la PC tienen que estar en la misma red.
- La resolución por defecto es `2430x1822@60`. Para tu modelo, exportá `IPAD_RES` (por ejemplo `IPAD_RES=2388x1668@60`) o cambiá el valor en `~/.local/bin/ipad-display-on.sh`.
- **Seguridad:** wayvnc queda escuchando en todas las interfaces (`0.0.0.0`) del puerto elegido (5900 por defecto), con usuario, contraseña y TLS obligatorios. Usá una contraseña fuerte y no lo expongas a internet ni lo dejes abierto en redes públicas. Si no lo usás, dejá el display apagado.
- Nunca subas `~/.config/wayvnc/` a un repo: tiene tu contraseña y tus claves privadas.

---

## arch-install

Instalador interactivo de Arch Linux con:

- Selección de disco y particionado automático
- Soporte **dual boot** con Windows (redimensiona partición NTFS automáticamente)
- Opciones: swap, home separado, entorno gráfico
- GRUB con detección de otros sistemas operativos

### Uso desde live ISO

```bash
# Conectarse a internet primero:
# WiFi:     iwctl station wlan0 connect "SSID"
# Ethernet: dhcpcd

curl -L https://raw.githubusercontent.com/avilasebastianm/arch-setup/main/arch-install/install.sh | bash
```

---

## Requisitos

- Arch Linux (live ISO o instalación base)
- Conexión a internet
- UEFI / GPT

## Capturas

> Escritorio con los dotfiles instalados — Hyprland · Waybar · Kitty · Rofi

![Captura del escritorio con los dotfiles instalados](assets/capture.png)

---

*Hecho en Buenos Aires 🇦🇷*
