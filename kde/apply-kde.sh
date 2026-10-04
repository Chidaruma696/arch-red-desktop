#!/usr/bin/env bash
# Applies the red Arch desktop settings to the running Plasma 6 session.
# install.sh calls it after the packages, the payload and the Tela icons are in place;
# it can also be run on its own to re-apply the look.
#
#   colors     ArchRed: Nothing OS style, pure black, white text, one red accent (#D71921)
#   icons      Tela-white-dark (Tela with a white variant, see tela-white.patch)
#   cursor     LK_Capitaine-Cursors; fonts Noto Sans 9 / FiraCode Nerd Font Mono 9
#   GTK        Material-Black-Red
#   panels     left bar + right bar (layout.js), cascading menu with the pixel Arch logo
#   dock       Latte (latte/ArchRed.layout.latte)
#   terminal   Ghostty as the default; Dolphin in details view
#   conky      KWin rule so the XWayland conky windows stay below and out of the taskbar
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
wallpaper="$HOME/.local/share/backgrounds/arch-red/tomie-agua.png"
menu_icon="$HOME/.local/share/icons/arch-desktop/arch-pixel-white.svg"
backup="$HOME/.local/share/arch-desktop/backups/kde-$(date +%Y%m%d-%H%M%S)"
step() { printf '\033[1;31m  ->\033[0m %s\n' "$*"; }

[[ ${XDG_CURRENT_DESKTOP:-} == *KDE* ]] || { echo "Run this from a Plasma session." >&2; exit 1; }
[[ -f $wallpaper ]] || { echo "Missing $wallpaper (install the payload first)." >&2; exit 1; }

# Keep only the launchers whose application exists here.
existing_desktops() {
    local d
    for d in "$@"; do
        [[ -f /usr/share/applications/$d ]] && printf '%s\n' "$d"
    done
    return 0
}

step "Backup of the Plasma config -> $backup"
mkdir -p "$backup"
for f in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kdeglobals kwinrc kwinrulesrc \
         kcminputrc kscreenlockerrc dolphinrc lattedockrc; do
    [[ -f "$HOME/.config/$f" ]] && cp -a "$HOME/.config/$f" "$backup/"
done

step "Colors, icons, cursor and fonts"
mkdir -p "$HOME/.local/share/color-schemes"
cp "$here/ArchRed.colors" "$HOME/.local/share/color-schemes/"
# re-applying a scheme with the same name is a no-op, so bounce through Breeze Dark
plasma-apply-colorscheme BreezeDark >/dev/null
plasma-apply-colorscheme ArchRed
plasma-apply-desktoptheme default >/dev/null || true
font="Noto Sans,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw() { kwriteconfig6 --notify "$@"; }
kw --file kdeglobals --group KDE --key contrast 0
kw --file kdeglobals --group Icons --key Theme Tela-white-dark
kw --file kdeglobals --group General --key font "$font"
kw --file kdeglobals --group General --key menuFont "$font"
kw --file kdeglobals --group General --key toolBarFont "$font"
kw --file kdeglobals --group General --key smallestReadableFont "Noto Sans,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw --file kdeglobals --group General --key fixed "FiraCode Nerd Font Mono,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw --file kdeglobals --group WM --key activeFont "Noto Sans,9,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
# plasma-apply-cursortheme does not list LK_Capitaine-Cursors, so set it directly
kw --file kcminputrc --group Mouse --key cursorTheme LK_Capitaine-Cursors
kw --file kcminputrc --group Mouse --key cursorSize 24
mkdir -p "$HOME/.icons/default"
printf '[icon theme]\nInherits=LK_Capitaine-Cursors\n' > "$HOME/.icons/default/index.theme"

step "GTK apps"
qdbus6 org.kde.kded6 /modules/gtkconfig org.kde.GtkConfig.setGtkTheme Material-Black-Red >/dev/null || true
for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    [[ -f $f ]] && sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=Tela-white-dark/; s/^gtk-font-name=.*/gtk-font-name=Noto Sans,  9/' "$f"
done
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme Tela-white-dark 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme LK_Capitaine-Cursors 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme Material-Black-Red 2>/dev/null || true
fi

step "Ghostty as the default terminal, Dolphin in details view"
kw --file kdeglobals --group General --key TerminalApplication ghostty
kw --file kdeglobals --group General --key TerminalService com.mitchellh.ghostty.desktop
printf 'com.mitchellh.ghostty.desktop\n' > "$HOME/.config/xdg-terminals.list"
kwriteconfig6 --file dolphinrc --group General --key GlobalViewProps true
kwriteconfig6 --file dolphinrc --group DetailsMode --key IconSize 32   # Tela is symbolic below 32
kwriteconfig6 --file dolphinrc --group DetailsMode --key PreviewSize 32
views="$HOME/.local/share/dolphin/view_properties/global/.directory"
mkdir -p "$(dirname "$views")"
kwriteconfig6 --file "$views" --group Dolphin --key Version 4
kwriteconfig6 --file "$views" --group Dolphin --key ViewMode 1

step "Four virtual desktops in two rows"
vdm=(qdbus6 org.kde.KWin /VirtualDesktopManager)
count=$("${vdm[@]}" org.kde.KWin.VirtualDesktopManager.count)
for ((i = count; i < 4; i++)); do
    "${vdm[@]}" org.kde.KWin.VirtualDesktopManager.createDesktop "$i" "Escritorio $((i + 1))" >/dev/null
done
busctl --user set-property org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager rows u 2

step "KWin rule for the conky windows"
rules="$(kreadconfig6 --file kwinrulesrc --group General --key rules)"
if [[ ,$rules, != *,conky-panels,* ]]; then
    rules="${rules:+$rules,}conky-panels"
    kwriteconfig6 --file kwinrulesrc --group General --key rules "$rules"
    kwriteconfig6 --file kwinrulesrc --group General --key count "$(tr ',' '\n' <<<"$rules" | grep -c .)"
fi
while IFS='=' read -r key value; do
    [[ -z $key || $key == \[* ]] && continue
    kwriteconfig6 --file kwinrulesrc --group conky-panels --key "$key" "$value"
done < "$here/kwinrulesrc-conky"
qdbus6 org.kde.KWin /KWin reconfigure

step "Lock screen wallpaper"
for key in Image PreviewImage; do
    kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image \
        --group General --key "$key" "file://$wallpaper"
done

step "Menu without sidebar (drop the global app favorites)"
db="$HOME/.local/share/kactivitymanagerd/resources/database"
if [[ -f $db ]] && command -v sqlite3 >/dev/null; then
    systemctl --user stop plasma-kactivitymanagerd
    sqlite3 "$db" "delete from ResourceLink where initiatingAgent='org.kde.plasma.favorites.applications';"
    systemctl --user start plasma-kactivitymanagerd
fi

step "Panels and wallpaper"
install -Dm644 "$here/arch-pixel-white.svg" "$menu_icon"
mapfile -t left < <(existing_desktops google-chrome.desktop com.mitchellh.ghostty.desktop \
                                      btop.desktop org.kde.dolphin.desktop)
left_json="[$(for d in "${left[@]}"; do printf '"/usr/share/applications/%s",' "$d"; done | sed 's/,$//')]"
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
    "$(sed "s|@WALLPAPER@|$wallpaper|; s|@MENU_ICON@|$menu_icon|; s|@LEFT_LAUNCHERS@|$left_json|" "$here/layout.js")" >/dev/null

step "Latte dock"
mapfile -t dock < <(existing_desktops google-chrome.desktop org.kde.dolphin.desktop \
                                      com.mitchellh.ghostty.desktop btop.desktop systemsettings.desktop)
dock_list="$(for d in "${dock[@]}"; do printf 'applications:%s,' "$d"; done | sed 's/,$//')"
mkdir -p "$HOME/.config/latte"
sed "s|@DOCK_LAUNCHERS@|$dock_list|" "$here/latte/ArchRed.layout.latte" > "$HOME/.config/latte/ArchRed.layout.latte"
kwriteconfig6 --file lattedockrc --group UniversalSettings --key singleModeLayoutName ArchRed
latte-dock-ng --enable-autostart >/dev/null 2>&1 || true
pkill -x latte-dock-ng || true
sleep 1
setsid -f latte-dock-ng --layout ArchRed >/dev/null 2>&1

step "Restarting plasmashell (it keeps stale tray icon colors until then)"
systemctl --user restart plasma-plasmashell

step "Conky"
if ! pgrep -x conky >/dev/null; then
    setsid -f "$HOME/.config/arch-conky/scripts/conky-launcher.sh" >/dev/null 2>&1
fi
