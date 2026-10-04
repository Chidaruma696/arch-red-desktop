// Plasma panel layout of the red Arch desktop: thin left bar (clock, tray, launchers,
// cascading menu) and a short right bar (monitors, pager, session). The bottom dock is Latte.
// apply-kde.sh fills @WALLPAPER@, @MENU_ICON@ and @LEFT_LAUNCHERS@ (a JSON list of the
// .desktop files that exist on this machine) and runs it through plasmashell evaluateScript.

panels().forEach(function (p) { p.remove(); });

function launcher(panel, desktopFile) {
    var w = panel.addWidget("org.kde.plasma.icon");
    w.currentConfigGroup = ["General"];
    w.writeConfig("url", "file://" + desktopFile);
    return w;
}

// Left bar: clock + tray on top, launchers and menu at the bottom
var left = new Panel;
left.location = "left";
left.height = 28;
left.lengthMode = "fill";
left.hiding = "none";
left.floating = false;

var clock = left.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", false);
clock.writeConfig("use24hFormat", 2);
clock.writeConfig("autoFontAndSize", false);
clock.writeConfig("fontFamily", "Noto Sans");
clock.writeConfig("fontSize", 8);

var tray = left.addWidget("org.kde.plasma.systemtray");
left.addWidget("org.kde.plasma.panelspacer");
@LEFT_LAUNCHERS@.forEach(function (f) { launcher(left, f); });
left.addWidget("org.kde.plasma.showdesktop");
// Cascading menu (antiX style) with the white pixel Arch logo from the conkys
var menu = left.addWidget("org.kde.plasma.kicker");
menu.currentConfigGroup = ["General"];
menu.writeConfig("useCustomButtonImage", true);
menu.writeConfig("customButtonImage", "@MENU_ICON@");
menu.writeConfig("alphaSort", true);
menu.writeConfig("showRecentApps", false);
menu.writeConfig("showRecentDocs", false);
menu.writeConfig("favoriteSystemActions", ["none"]);  // no session buttons in the sidebar

// Right bar: short, anchored to the bottom, windows may cover it
var right = new Panel;
right.location = "right";
right.height = 36;
right.lengthMode = "fit";
right.alignment = "right";
right.hiding = "windowscover";
right.floating = false;

right.addWidget("org.kde.plasma.systemmonitor.net");
right.addWidget("org.kde.plasma.systemmonitor.cpu");
right.addWidget("org.kde.plasma.systemmonitor.memory");
right.addWidget("org.kde.plasma.systemmonitor.diskactivity");
right.addWidget("org.kde.plasma.pager");
var session = right.addWidget("org.kde.plasma.lock_logout");
session.currentConfigGroup = ["General"];
session.writeConfig("show_lockScreen", true);
session.writeConfig("show_requestShutDown", true);
session.writeConfig("show_requestLogout", true);
session.writeConfig("show_requestReboot", false);
session.writeConfig("show_switchUser", false);
session.writeConfig("show_requestLogoutScreen", false);

// Bottom dock: Latte (see latte/ArchRed.layout.latte)

// Wallpaper on every desktop
desktops().forEach(function (d) {
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file://@WALLPAPER@");
    d.writeConfig("FillMode", 2);
});
