#!/usr/bin/env bash
# Turns a fresh Arch Linux install into the red Arch desktop: KDE Plasma 6 (minimal),
# Ghostty and Google Chrome, nothing else, plus the whole look.
#
#   look       ArchRed color scheme (Nothing OS style: pure black, white, one red accent),
#              Tela-white-dark icons, LK_Capitaine cursor, Material-Black-Red for GTK apps
#   wallpaper  Junji Ito's Tomie tinted red (tomie-agua.png); the other red Junji Ito
#              wallpapers and Chen Rong's "Nine Dragons" come along as alternatives
#   panels     thin left bar (clock, tray, launchers, cascading menu with a pixel Arch logo),
#              short right bar (net/cpu/mem/disk, pager, lock/shutdown/logout), Latte dock
#   conky      left: LED clock (12 h + date), ThinkPad, Core Matrix, Pending Updates;
#              right: Arch header, resources, network, Docker, system, Alerts
#   apps       Ghostty (default terminal, Tango on black) and Google Chrome (AUR)
#
# It can run from a TTY right after installing Arch: if Plasma is missing it installs a
# minimal Plasma with SDDM, and since the Plasma settings need a running session, they are
# applied by a one-shot autostart the first time you log in. From inside Plasma it applies
# them right away.
#
# Everything is installed per user under $HOME; outside $HOME only packages and services
# are touched. What gets overwritten is backed up first (~/.local/share/arch-desktop/backups).
#
# Usage (as your normal user, with sudo):
#   ./install.sh                 everything
#   ./install.sh --no-packages   skip pacman and the AUR (everything already installed)
#   ./install.sh --no-chrome     do not build google-chrome from the AUR
#   ./install.sh --files-only    copy files only; no packages, no Plasma settings
#
# Made for a 1920x1200 screen: on other resolutions the conky panels with fixed positions
# need their gap_x/gap_y adjusted in ~/.config/arch-conky/configs.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$HERE/payload.tar.zst"
TELA_REPO="https://github.com/vinceliuice/Tela-icon-theme.git"
TELA_COMMIT="a1fffc5bfab716bd022dd228ee96fe3965cdb33d"
DESKTOP_DIR="$HOME/.local/share/arch-desktop"
FIRSTRUN="$HOME/.config/autostart/arch-red-firstrun.desktop"
DO_PACKAGES=1
DO_APPLY=1
DO_CHROME=1
for arg in "$@"; do
    case "$arg" in
        --no-packages) DO_PACKAGES=0 ;;
        --no-chrome)   DO_CHROME=0 ;;
        --files-only)  DO_PACKAGES=0; DO_APPLY=0 ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 1 ;;
    esac
done

[[ $EUID -ne 0 ]] || { echo "Run this as your normal user, not root." >&2; exit 1; }
[[ -f $PAYLOAD ]] || { echo "Missing $PAYLOAD" >&2; exit 1; }

# Minimal Plasma, only when it is not installed yet.
PLASMA=(
    plasma-desktop plasma-nm plasma-pa powerdevil kscreen bluedevil polkit-kde-agent
    xdg-desktop-portal-kde sddm sddm-kcm
)
PACKAGES=(
    ghostty
    # conky and what its scripts call
    conky jq curl lm_sensors pacman-contrib xorg-xrandr xorg-xprop xdotool python
    # fonts
    ttf-fira-sans ttf-firacode-nerd noto-fonts
    # GTK theming under Plasma, settings tools, building from the AUR
    kde-gtk-config breeze-gtk sqlite zstd git base-devel
)
AUR_PACKAGES=(latte-dock-ng)
(( DO_CHROME )) && AUR_PACKAGES+=(google-chrome)

step() { printf '\n\033[1;31m==>\033[0m \033[1m%s\033[0m\n' "$*"; }

# ---------------------------------------------------------------- packages
aur_install() {
    local pkg="$1" helper build
    pacman -Q "$pkg" >/dev/null 2>&1 && { echo "  $pkg already installed"; return; }
    for helper in paru yay; do
        if command -v "$helper" >/dev/null; then
            "$helper" -S --needed --noconfirm "$pkg"
            return
        fi
    done
    build="$(mktemp -d)"
    git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "$build/$pkg"
    (cd "$build/$pkg" && makepkg -si --needed --noconfirm)
    rm -rf "$build"
}

# Enables NetworkManager only when nothing else manages the network.
enable_network() {
    local s
    for s in systemd-networkd iwd dhcpcd connman; do
        if systemctl is-enabled --quiet "$s" 2>/dev/null; then
            echo "  $s is enabled; leaving the network as it is (plasma-nm needs NetworkManager)"
            return
        fi
    done
    sudo systemctl enable NetworkManager
}

if (( DO_PACKAGES )); then
    command -v pacman >/dev/null || { echo "This script is for Arch Linux (pacman not found)." >&2; exit 1; }
    if ! pacman -Q plasma-desktop >/dev/null 2>&1; then
        step "Installing a minimal Plasma with SDDM"
        extra=()
        # plasma-pa needs a PulseAudio server; use PipeWire unless PulseAudio is already there
        pacman -Q pulseaudio >/dev/null 2>&1 || extra=(pipewire pipewire-pulse wireplumber)
        sudo pacman -S --needed --noconfirm "${PLASMA[@]}" "${extra[@]}"
        sudo systemctl enable sddm
        enable_network
    fi
    step "Installing packages (sudo pacman -S --needed)"
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
    step "AUR: ${AUR_PACKAGES[*]}"
    for p in "${AUR_PACKAGES[@]}"; do aur_install "$p"; done
fi

# ---------------------------------------------------------------- Tela white
TELA_DEST="$HOME/.local/share/icons"
if [[ -d $TELA_DEST/Tela-white-dark ]]; then
    step "Tela-white icons already in $TELA_DEST"
else
    step "Building Tela-white icons (Tela $TELA_COMMIT + kde/tela-white.patch)"
    tela="$(mktemp -d)"
    git -C "$tela" init -q
    git -C "$tela" fetch -q --depth 1 "$TELA_REPO" "$TELA_COMMIT"
    git -C "$tela" checkout -q FETCH_HEAD
    patch -s "$tela/install.sh" < "$HERE/kde/tela-white.patch"
    (cd "$tela" && ./install.sh -d "$TELA_DEST" white >/dev/null)
    rm -rf "$tela"
fi

# ---------------------------------------------------------------- unpack
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
step "Unpacking payload"
tar --zstd -xf "$PAYLOAD" -C "$STAGE"
grep -rlIZ '@HOME@' "$STAGE" | xargs -0 -r sed -i "s#@HOME@#$HOME#g"

# ---------------------------------------------------------------- backup
BACKUP="$DESKTOP_DIR/backups/before-install-$(date +%Y%m%d-%H%M%S).tar.gz"
mkdir -p "$DESKTOP_DIR/backups"
step "Backing up what will be overwritten -> $BACKUP"
to_backup=()
for rel in .config/arch-conky .config/autostart/arch-conky.desktop .config/ghostty/config.ghostty \
           .themes/Material-Black-Red .icons/LK_Capitaine-Cursors \
           .local/share/fonts/dseg .local/share/backgrounds/arch-red; do
    [[ -e "$HOME/$rel" ]] && to_backup+=("$rel")
done
if (( ${#to_backup[@]} )); then
    tar -czf "$BACKUP" -C "$HOME" "${to_backup[@]}" 2>/dev/null || true
else
    echo "(nothing to back up)"
fi

# ---------------------------------------------------------------- files
step "Copying conky, Ghostty, GTK theme, cursor, fonts and wallpapers"
cp -a "$STAGE/home/." "$HOME/"
chmod +x "$HOME/.config/arch-conky/scripts/"*.sh
mkdir -p "$HOME/.config/arch-conky/data"

# The right column was made on wlp3s0; point it at whatever interface has the default route.
iface="$(ip route show default 2>/dev/null | awk '{print $5; exit}')"
if [[ -n $iface && $iface != wlp3s0 ]]; then
    sed -i "s/wlp3s0/$iface/g" "$HOME/.config/arch-conky/configs/conkyrc-right.conf"
    echo "  conky: network panel uses $iface"
fi
fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true

# The Plasma settings script and its files live in $HOME, so the clone can be deleted.
rm -rf "$DESKTOP_DIR/kde"
cp -a "$HERE/kde" "$DESKTOP_DIR/kde"

if (( ! DO_APPLY )); then
    step "Files copied (--files-only). Run $DESKTOP_DIR/kde/apply-kde.sh from Plasma to apply the look."
    exit 0
fi

# ---------------------------------------------------------------- Plasma
if [[ ${XDG_CURRENT_DESKTOP:-} == *KDE* ]]; then
    step "Applying the Plasma settings"
    "$DESKTOP_DIR/kde/apply-kde.sh"
    next="Log out and back in once so the cursor, fonts and GTK apps pick everything up."
else
    step "Plasma is not running: the look will be applied on the first Plasma login"
    mkdir -p "$(dirname "$FIRSTRUN")"
    cat > "$FIRSTRUN" <<EOF
[Desktop Entry]
Type=Application
Name=Red Arch desktop (first run)
Exec=$DESKTOP_DIR/kde/firstrun.sh
OnlyShowIn=KDE;
X-KDE-autostart-after=panel
EOF
    next="Reboot, choose \"Plasma (Wayland)\" in SDDM and log in: the look is applied by itself
in a few seconds (log: $DESKTOP_DIR/firstrun.log). Log out and back in once afterwards."
fi

step "Done"
cat <<EOF
$next

Notes:
  - Backups: $BACKUP and $DESKTOP_DIR/backups/kde-*
  - Conky panels: ~/.config/arch-conky (data script: scripts/arch-status.sh). The ThinkPad
    panel reads thinkpad_acpi and stays blank on other laptops; the Docker, Tailscale and
    firewall lines stay empty if those are not installed.
  - For temperatures, run 'sudo sensors-detect' once if 'sensors' shows nothing.
  - Wallpapers: ~/.local/share/backgrounds/arch-red (Junji Ito fan art from Wallhaven,
    personal use only, sources in JUNJI-ITO-SOURCES.txt; Nine Dragons is public domain).
  - Tomie (desktop pet) ships paused: uncomment "conkyrc-tomie.conf" in the panels list
    of scripts/conky-launcher.sh to bring her back.
EOF
