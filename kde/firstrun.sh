#!/usr/bin/env bash
# One-shot: applies the Plasma settings on the first login after a TTY install,
# then removes its own autostart entry. Started from arch-red-firstrun.desktop.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
log="$HOME/.local/share/arch-desktop/firstrun.log"
autostart="$HOME/.config/autostart/arch-red-firstrun.desktop"

exec >>"$log" 2>&1
echo "== $(date '+%F %T') first run"

# plasmashell has to be up before its panels can be scripted
for _ in $(seq 60); do
    qdbus6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 && break
    sleep 1
done
sleep 3

if "$here/apply-kde.sh"; then
    rm -f "$autostart"
    echo "== done"
else
    echo "== apply-kde.sh failed; the autostart stays so it is retried on the next login"
fi
