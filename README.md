# Nothing KDE

A Nothing-inspired Plasma 6 theme suite with a top island, bottom dock, eight desktop widgets,
Glassy application styling, and optional application accent integrations. The UI is localized
in Turkish and English; no custom daemon is required.

## Install

Requires Plasma 6.7, Qt 6.10+, Bash, Python 3, `kpackagetool6`, `qdbus6`, and KDE
package/configuration tools.

Optional backends used by related controls: NetworkManager (`nmcli`), PipeWire (`wpctl`,
`pactl`), BlueZ, PowerDevil, `brightnessctl`, `upower`, and `powerprofilesctl`.

```sh
git clone https://github.com/Contraill/Nothing-Kde-Theme.git
cd Nothing-Kde-Theme
./install.sh                  # install / upgrade
./install.sh --apply-layout   # create/repair the two panels; Plasma is reloaded
./install.sh --widgets-only   # desktop widgets only
```

Choose **Nothing KDE Dark** or **Nothing KDE Light** in System Settings. Add the desktop
widgets through **Add Widgets**.

### Boot login wallpaper (Plasma Login Manager)

The boot login screen has separate system-wide settings from the desktop and lock screen.
On systems using **Plasma Login Manager**, apply Nothing's wallpaper explicitly:

```sh
./install.sh --login-wallpaper dark   # or light; asks for administrator authentication
```

The selected image appears at the next boot login. To undo only this setting, run
`./install.sh --login-wallpaper remove`.

This installs public image copies and a wallpaper-only configuration drop-in. It does not
change authentication, auto-login or the running session. Existing administrator settings
in `/etc/plasmalogin.conf` retain precedence, including custom wallpaper choices. The boot
wallpaper is a fixed selection; changing a user's desktop mode does not change the shared
login screen. Uninstall removes the optional integration and exposes the previous settings;
files edited after installation are preserved with an error rather than overwritten.
SDDM uses a different configuration and is not changed by this command.

Desktop widgets share a palette-driven Glassy surface; images and artwork keep their own
content. Normal desktop applets share the wallpaper's window, so the widget surface uses
translucency rather than fake blur or an external effect
([KDE desktop view](https://invent.kde.org/plasma/plasma-workspace/-/blob/master/shell/desktopview.cpp)).

Existing panels are retained. `--apply-layout` creates a backup first and removes only
retired Nothing side panels.

## Glassy

The bundle includes the reusable **Glassy** Kvantum theme and native **Glassy** Aurorae
window decoration. Both follow KDE colors and do not depend on the Nothing palette.
Select `Kvantum` as the KDE application style and `Glassy` in Kvantum Manager; the window
decoration is also named `Glassy`.

**Glassy Settings** is available from the application launcher. The Application, Glass,
Window Decoration, and Controls tabs share the same `auroraerc` /
`[org.glassy.decoration]` configuration. **Reset to Glassy defaults** resets only this form,
and changes are staged until **Apply**. The same settings form is available under
**System Settings → Window Decorations → Glassy → Configure**.

The small native settings utility requires CMake/C++ when built from source; it is not a
style engine.

```sh
./install.sh --appearance install     # Glassy only
./install.sh --appearance sync        # after palette changes
./install.sh --appearance disable     # restore previous selections
```

Installed dependencies are reused and uninstalling never removes packages. Ownership and
previous appearance selections are recorded in:

```text
~/.config/nothing-kde/appearance/state.json
```

The island triggers palette synchronization. If Glassy is used with another theme or panel,
connect `sync` to that theme's color change path. There is no separate daemon.

Glassy targets Qt Widgets. System Settings' Qt Quick pages, GTK applications, and Electron
content are outside Kvantum's scope and may remain opaque.

**Important:** Qt palettes update live in running applications, but cached Kvantum surfaces
and SVG control colors do not all update live yet. Eleven unnecessary color overrides were
removed, and restarting applications is not treated as a final solution. See the
[live-palette audit](assets/kvantum/LIVE-PALETTE.md) and
[Glassy integration notes](assets/kvantum/README.md).

On an actual light/dark transition, if running Kvantum applications are detected, one
deduplicated native notification explains that some open applications may need to be reopened.
Startup and accent-only updates stay silent. No application is restarted automatically.

## Optional integrations

```sh
./install.sh --dolphin apply
./install.sh --dolphin restore
./install.sh --accent-links enable fastfetch   # starship | spaceship | fastfetch
./install.sh --accent-links disable all
```

Accent links can also be managed from the island's settings. Starship/Fish and Spaceship/Zsh
need a new terminal after first enabling the integration; Fastfetch updates on its next run.

Starship uses contrast-aware segment foregrounds and KDE palette text. The original prompt
layout/configuration is preserved, and linked colors update on the next prompt render.

Expand the island and left-click the gear for island settings; right-click it for KDE System
Settings. The island can switch Light/Dark mode and provides a visual color picker or manual
HEX input for the accent. The persistent accent source is KDE `General/AccentColor`; startup
and mode switching preserve it. Closing the picker discards unapplied changes.

If Kitty is installed, the integration manages Kitty's official
`light-theme.auto.conf`, `dark-theme.auto.conf`, and `no-preference-theme.auto.conf` files.
The main `kitty.conf`, opacity/blur settings, and the 16 ANSI colors are preserved. Kitty
applies OS light/dark changes live; managed file changes use the official SIGUSR1 reload path.
Processes launched with a custom `--config` are not signaled.

Restore Kitty integration with:

```sh
./install.sh --kitty-theme disable
```

Previous automatic-theme files are preserved, and files edited by the user after integration
are not overwritten. Removing automatic themes may require manually reopening Kitty to discard
its cached theme; the integration never restarts a process.
See [Kitty's official automatic themes documentation](https://sw.kovidgoyal.net/kitty/kittens/themes/#change-color-themes-automatically-when-the-os-switches-between-light-and-dark).

No icon theme is required, installed, or selected automatically. [Colloid](https://github.com/vinceliuice/Colloid-icon-theme)
is an optional recommendation because of its modern appearance, Glassy fit, and KDE
palette-aware folder tinting. Colloid's `--notint` option disables its KDE tint support.

**Confirm power actions** is enabled by default in island settings. Disabling it removes only
the panel's own confirmation step; KDE/Polkit rules are unchanged. The preference is stored in
panel configuration and applies to the panel's power actions, including suspend.

### Manual persistence check

Choose a different accent and Light/Dark mode, change the Glassy radius/bottom-corner setting,
and toggle panel power confirmation. First log out and back in, then reboot when convenient and
confirm that the same values remain.

When power confirmation is disabled, actions can execute immediately, so test only after saving
your work. Automated tests do not execute real shutdown, logout, or suspend operations.

### Dolphin

The Dolphin profile follows KDE colors and uses a scoped Qt stylesheet rather than a global
style. Launch Dolphin from the dock/menu to ensure the Qt style is loaded; a first launch
directly through a terminal or D-Bus can bypass that startup path. Personal folder settings are
preserved.

Backups for reversible application links live in `~/.config/nothing-kde/`; do not delete them
while an integration is enabled. Use `--dolphin status` or `--accent-links status` to inspect
their state.

### Limine

Limine 12 integration is export-only; boot files are never modified:

```sh
./install.sh --accent-links export limine \
  --source /path/limine.conf \
  --output /tmp/limine-preview.conf
```

## Notifications and privacy

The optional Glyph notification adapter checks the installed KDE notification QML/API
structure rather than requiring an exact Plasma patch version. It verifies notification
resources, model callbacks, and popup APIs. If compatibility cannot be established, the
native KDE notification appearance is retained.

Compatibility inspection uses a temporary Qt 6 probe and therefore needs a C++ compiler,
`pkg-config`, and Qt Core/Qml/Gui headers. If those tools are missing, the optional skin is
safely skipped.

Install the notification appearance with:

```sh
./install.sh --notifications-only --restart-plasma
```

Explicitly override only the compatibility gate with:

```sh
./install.sh --notifications-only --force-notifications --restart-plasma
```

`--force-notifications` bypasses compatibility detection only. QML validation, local service
checks, and rollback remain active. No notification daemon or system KDE resource is replaced.

Restore the previous notification appearance with:

```sh
./notification-skin/rollback-native.sh
```

Microphone blocking is not a mute toggle. With administrator approval, it denies local ALSA
capture access and persists across reboot; audio services briefly restart. Bluetooth, virtual,
network, and OSS capture devices, as well as root access, are outside its scope. USB camera
blocking targets USB Video interfaces and may reset after reconnect or reboot.

Privacy controls require Polkit, ACL tools, udev, systemd, and PipeWire/WirePlumber.

**Unblock the microphone before uninstalling:**

```sh
pkexec /usr/bin/python3 -I "$PWD/runtime/privacy.py" microphone on
./uninstall.sh
```

Store-only recovery helper:

```text
~/.local/share/plasma/plasmoids/com.nothingplasma.panel/contents/tools/privacy.py
```

Click the island weather area to choose a city or refresh the data. Open-Meteo receives the
city search/coordinates and your IP; no API key is needed.
[Weather data](https://open-meteo.com/) uses CC BY 4.0. The selected location is stored in
panel configuration.

Launcher settings list installed applications; visibility choices apply to this launcher and
its search results.

The island's appearance settings include **Show system tray** and **Configure tray items**.
The latter opens KDE's native per-application visibility settings and remains available when
the entire tray is hidden. These choices persist in Plasma configuration; updating Nothing
does not reset an existing tray. Application icons appear between the player and battery.

Drag dock icons to preview a new order; releasing commits it once. Releasing above or below
the dock cancels the move. Right-click menus include actions supplied by the application's
desktop entry, when available (for example Steam's Big Picture action).
An icon with windows on another workspace has a small dot; hover to see the workspace
names in the window preview. Windows shown on all workspaces are not marked. Right-click
the launcher's settings button to open KDE System Settings; left-click opens launcher settings.

With automatic wallpaper enabled, Nothing reapplies its light/dark pair after panel startup,
screen changes and activity changes. Custom images and other wallpaper plugins are preserved,
including overrides on previously themed screens. Empty wallpaper settings and KDE's stock
`Next` wallpaper are treated as unconfigured desktops. To deliberately keep `Next`, turn off
automatic wallpaper in Nothing's settings.

## Test and package

```sh
./validate.sh
./package.sh                           # artifacts: dist/
./package.sh --output /tmp/nothing-kde-dist
NOTHING_PACKAGE_DIR=/tmp/nothing-kde-dist ./validate.sh

# Optional native dock and notification geometry tests (require QApplication):
cmake -S tests/qml-native -B /tmp/nothing-native-tests
cmake --build /tmp/nothing-native-tests
NOTHING_NATIVE_QML_RUNNER=/tmp/nothing-native-tests/nothing-native-quick ./validate.sh
```

Qt QML tools enable lint and interaction tests. `msgfmt` rebuilds the Turkish localization
catalogs. Pinned KDE sources and compiled translations are retained for offline packaging.

Store dependencies can be prepared with:

```sh
./package.sh --store-ids packaging/store-ids.json
```

Use the structure in `packaging/store-ids.example.json` and real published component IDs.

**Store publication is not yet cleared.** Widget font/artwork permissions, wallpaper
redistribution rights, and real Store IDs must be resolved first.

License and attribution:
[GPL](LICENSE),
[Island attribution](plasmoids/com.nothingplasma.panel/contents/island/NOTICE.md),
[widget sources](widgets/UPSTREAM.json), and each widget's `UPSTREAM-NOTICE.md`.

Existing `com.nothingplasma.*` IDs remain stable to preserve panels and pinned applications.
