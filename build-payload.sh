#!/usr/bin/env bash
# Builds payload.tar.zst from the red Plasma desktop as it is right now on this machine.
#
# What goes in (as a mirror of $HOME, with @HOME@ in place of the home path):
#   - conky:      ~/.config/kodachi/conky        -> ~/.config/arch-conky
#   - autostart:  the conky launcher entry       -> ~/.config/autostart/arch-conky.desktop
#   - terminal:   ~/.config/ghostty/config.ghostty
#   - GTK theme:  ~/.themes/Material-Black-Red
#   - cursor:     ~/.icons/LK_Capitaine-Cursors
#   - fonts:      DSEG7/DSEG14 Classic (OFL, AUR-only package) -> ~/.local/share/fonts
#   - wallpapers: ~/Imágenes/Wallpapers/junji-ito-rojo + ~/.local/share/backgrounds/arch-red
#                 -> ~/.local/share/backgrounds/arch-red
# Plasma settings, Latte, the menu icon and the Tela patch live in kde/ as plain files.
# Paths are rewritten (kodachi -> arch-conky, $HOME -> @HOME@) so it installs for any user.
# The previous payload is kept as payload-prev.tar.zst.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$HERE/payload.tar.zst"

LIVE_CONKY="$HOME/.config/kodachi/conky"
LIVE_AUTOSTART="$HOME/.config/autostart/arch-conky.desktop"
LIVE_WALLS=("$HOME/Imágenes/Wallpapers/junji-ito-rojo" "$HOME/.local/share/backgrounds/arch-red")
WALLPAPER="tomie-agua.png"

for p in "$LIVE_CONKY" "$LIVE_AUTOSTART" "$HOME/.config/ghostty/config.ghostty" \
         "$HOME/.themes/Material-Black-Red" "$HOME/.icons/LK_Capitaine-Cursors"; do
    [[ -e $p ]] || { echo "Missing $p" >&2; exit 1; }
done

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
H="$STAGE/home"
step() { printf '\033[1;31m==>\033[0m %s\n' "$*"; }

# Rewrite paths in every text file under a directory.
rewrite() {
    grep -rlIZ -e "$HOME" -e kodachi "$1" | xargs -0 -r sed -i \
        -e "s#$HOME/\.config/kodachi/conky#@HOME@/.config/arch-conky#g" \
        -e "s#kodachi/conky/#arch-conky/#g" \
        -e "s#kodachi/conky\b#arch-conky#g" \
        -e "s#kodachi-conky-#arch-conky-#g" \
        -e "s#\.cache/kodachi/conky-error\.log#.cache/arch-conky-error.log#g" \
        -e "s#$HOME#@HOME@#g"
}

step "Conky"
mkdir -p "$H/.config/arch-conky"
tar -C "$LIVE_CONKY" \
    --exclude='./data' --exclude='*.orig' --exclude='*.bak-*' --exclude='*.bak' \
    --exclude='./autostart' --exclude='./systemd' --exclude='conkyrc-pet.conf' \
    -cf - . | tar -C "$H/.config/arch-conky" -xf -
install -Dm644 "$LIVE_AUTOSTART" "$H/.config/autostart/arch-conky.desktop"
rewrite "$H/.config"

step "Ghostty"
install -Dm644 "$HOME/.config/ghostty/config.ghostty" "$H/.config/ghostty/config.ghostty"

step "GTK theme and cursor"
mkdir -p "$H/.themes" "$H/.icons"
cp -a "$HOME/.themes/Material-Black-Red" "$H/.themes/"
cp -a "$HOME/.icons/LK_Capitaine-Cursors" "$H/.icons/"

step "Fonts (DSEG Classic)"
mkdir -p "$H/.local/share/fonts/dseg"
cp /usr/share/fonts/TTF/DSEG7Classic-*.ttf /usr/share/fonts/TTF/DSEG14Classic-*.ttf "$H/.local/share/fonts/dseg/"
cp /usr/share/licenses/ttf-dseg/* "$H/.local/share/fonts/dseg/" 2>/dev/null || true

step "Wallpapers"
BG="$H/.local/share/backgrounds/arch-red"
mkdir -p "$BG"
for d in "${LIVE_WALLS[@]}"; do
    [[ -d $d ]] || continue
    find "$d" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.txt' \) -exec cp -a {} "$BG/" \;
done
[[ -f "$BG/FUENTES.txt" ]] && mv "$BG/FUENTES.txt" "$BG/JUNJI-ITO-SOURCES.txt"
[[ -f "$BG/$WALLPAPER" ]] || { echo "Wallpaper $WALLPAPER not found" >&2; exit 1; }

step "Checking"
leaks="$(grep -rlI -e "$HOME" -e 'kodachi/conky' "$STAGE" || true)"
if [[ -n $leaks ]]; then
    echo "Paths that were not rewritten:" >&2
    echo "$leaks" >&2
    exit 1
fi
for f in $(grep -rhoI '@HOME@/[^" ]*\.lua' "$H/.config/arch-conky/configs" | sort -u); do
    [[ -f "$H/${f#@HOME@/}" ]] || { echo "lua_load target missing: $f" >&2; exit 1; }
done

step "Packing"
[[ -f $PAYLOAD ]] && cp -a "$PAYLOAD" "$HERE/payload-prev.tar.zst"
tar -C "$STAGE" -cf - home | zstd -q -19 -T0 -o "$PAYLOAD.new"
mv "$PAYLOAD.new" "$PAYLOAD"
du -h "$PAYLOAD"
