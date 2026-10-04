[English](README.md) · **Español**

# arch-red-desktop

Mi escritorio, empaquetado para que un Arch recién instalado quede igual: KDE Plasma 6 (mínimo),
Ghostty y Google Chrome, nada más, y todo el look rojo y negro.

- **Colores:** ArchRed, estilo Nothing OS: negro puro, texto blanco y un solo rojo (#D71921).
- **Iconos:** Tela con carpetas blancas (se compila desde Tela + `kde/tela-white.patch`).
- **Paneles:** barra fina a la izquierda (reloj, bandeja, lanzadores, menú en cascada con el logo
  de Arch pixelado), barra corta a la derecha (red/CPU/memoria/disco, escritorios, sesión) y un
  dock Latte.
- **Conky:** reloj LED (12 h + fecha), ThinkPad, Core Matrix y Pending Updates a la izquierda;
  Arch, recursos, red, Docker, sistema y alertas a la derecha.
- **Fondo:** Tomie de Junji Ito teñida de rojo.
- **Ghostty:** la terminal por defecto, Tango sobre negro.

Hecho en una ThinkPad L14 a 1920x1200; en otras pantallas hay que mover los conkys, y el panel
de ThinkPad sale vacío en otros portátiles.

## Instalación

Desde la TTY justo después de instalar Arch (basta un `archinstall` sencillo con un usuario con
sudo), o desde una sesión de Plasma que ya tengas:

```sh
sudo pacman -S --needed git
git clone https://github.com/Chidaruma696/arch-red-desktop.git
cd arch-red-desktop
./install.sh
```

Si no hay Plasma, pone uno mínimo con SDDM. Ghostty y lo que necesitan los conkys salen de los
repos oficiales; Latte (`latte-dock-ng`) y `google-chrome` se compilan desde AUR. Desde la TTY
los ajustes de Plasma todavía no se pueden aplicar, así que se aplican solos en el primer inicio
de sesión: reinicia, elige "Plasma (Wayland)" y espera unos segundos. Después cierra sesión y
vuelve a entrar una vez.

Opciones: `--no-chrome`, `--no-packages` (si ya está todo instalado) y `--files-only`.
Lo que se sobrescribe se guarda antes en `~/.local/share/arch-desktop/backups`.

## Qué hay aquí

- `install.sh`: paquetes, AUR, Tela, payload y ajustes de Plasma.
- `kde/`: `apply-kde.sh` (la parte de Plasma, se puede volver a correr sola), el esquema de
  colores, el script de paneles, la distribución de Latte, la regla de KWin para conky y el
  parche de Tela.
- `payload.tar.zst`: conky, config de Ghostty, tema GTK, cursor, fuentes LED y fondos.
- `build-payload.sh`: rehace el payload desde mi escritorio.

## Créditos

- Paneles de conky: parten de los de [Kodachi OS](https://www.kodachi.cloud), de Warith Al Maawali
  (licencia de Kodachi, no comercial; las cabeceras originales siguen en los scripts), reescritos
  para Arch.
- [Tela icon theme](https://github.com/vinceliuice/Tela-icon-theme), de vinceliuice (GPL-3.0).
- Tema GTK Material-Black (GPL-2.0), pasado a rojo; cursores Capitaine (LGPL-3.0).
- Fuentes LED [DSEG](https://www.keshikan.net/fonts-e.html), de keshikan (OFL-1.1).
- Fondos: fan art de Junji Ito de Wallhaven, solo uso personal (fuentes en
  `JUNJI-ITO-SOURCES.txt`); "Nueve dragones" de Chen Rong (dominio público).
- Fotogramas de la mascota Tomie, de kummmo (viene pausada).

Mis scripts (`install.sh`, `build-payload.sh`, `kde/`) son MIT, ver [LICENSE](LICENSE).
