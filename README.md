**English** · [Español](README.es.md)

# arch-red-desktop

My desktop, packed so a fresh Arch install ends up looking the same: KDE Plasma 6 (minimal),
Ghostty and Google Chrome, nothing else, plus the whole red-and-black look.

- **Colors:** ArchRed, Nothing OS style: pure black, white text and a single red accent (#D71921).
- **Icons:** Tela with a white folder variant (built from Tela + `kde/tela-white.patch`).
- **Panels:** a thin left bar (clock, tray, launchers, cascading menu with a pixel Arch logo),
  a short right bar (network/CPU/memory/disk, pager, session) and a Latte dock.
- **Conky:** LED clock (12 h + date), ThinkPad, Core Matrix and Pending Updates on the left;
  Arch, resources, network, Docker, system and alerts on the right.
- **Wallpaper:** Junji Ito's Tomie tinted red.
- **Ghostty:** the default terminal, Tango on black.

Made on a ThinkPad L14 at 1920x1200; on other screens the conky panels need moving, and the
ThinkPad panel stays blank on other laptops.

## Install

From the TTY right after installing Arch (a plain `archinstall` with a user that has sudo is
enough), or from an existing Plasma session:

```sh
sudo pacman -S --needed git
git clone https://github.com/Chidaruma696/arch-red-desktop.git
cd arch-red-desktop
./install.sh
```

If Plasma is not installed it adds a minimal one with SDDM. Ghostty and the conky dependencies
come from the official repos; Latte (`latte-dock-ng`) and `google-chrome` are built from the AUR.
From a TTY the Plasma settings can't be applied yet, so they run by themselves on the first
login: reboot, pick "Plasma (Wayland)" and wait a few seconds. Log out and back in once after
that.

Options: `--no-chrome`, `--no-packages` (everything already installed) and `--files-only`.
Whatever gets overwritten is backed up to `~/.local/share/arch-desktop/backups`.

## Layout

- `install.sh`: packages, AUR, Tela, payload and Plasma settings.
- `kde/`: `apply-kde.sh` (the Plasma part, can be run again on its own), the color scheme,
  the panel script, the Latte layout, the KWin rule for conky and the Tela patch.
- `payload.tar.zst`: conky, Ghostty config, GTK theme, cursor, LED fonts and wallpapers.
- `build-payload.sh`: rebuilds the payload from my running desktop.

## Credits

- Conky panels: started from the ones in [Kodachi OS](https://www.kodachi.cloud) by Warith Al Maawali
  (Kodachi license, non-commercial; the original headers stay in the scripts), rewritten for Arch.
- [Tela icon theme](https://github.com/vinceliuice/Tela-icon-theme) by vinceliuice (GPL-3.0).
- Material-Black GTK theme (GPL-2.0), recolored red; Capitaine cursors (LGPL-3.0).
- [DSEG](https://www.keshikan.net/fonts-e.html) LED fonts by keshikan (OFL-1.1).
- Wallpapers: Junji Ito fan art from Wallhaven, personal use only (sources in
  `JUNJI-ITO-SOURCES.txt`); "Nine Dragons" by Chen Rong (public domain).
- Tomie desktop pet frames by kummmo (ships paused).

My own scripts (`install.sh`, `build-payload.sh`, `kde/`) are MIT, see [LICENSE](LICENSE).
