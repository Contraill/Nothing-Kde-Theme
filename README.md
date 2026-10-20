# Nothing KDE

[![CI](https://github.com/Contraill/Nothing-Kde-Theme/actions/workflows/ci.yml/badge.svg)](https://github.com/Contraill/Nothing-Kde-Theme/actions/workflows/ci.yml)
[![Version](https://img.shields.io/github/v/tag/Contraill/Nothing-Kde-Theme?sort=semver&label=version)](https://github.com/Contraill/Nothing-Kde-Theme/tags)
[![License: GPL-3.0-or-later](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)](LICENSE)

A Nothing-inspired theme suite for Plasma 6: a top island, a bottom dock, nineteen desktop
widgets, the Glassy application style and accent links for other apps. In English and
Turkish, with no daemon of its own.

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/desktop.png" alt="Nothing KDE desktop with the top island, desktop widgets and bottom dock"></td>
    <td width="50%"><img src="docs/screenshots/control-center.png" alt="Expanded island with Wi-Fi, Bluetooth, sound, brightness, the player, power profiles and system stats"></td>
  </tr>
  <tr>
    <td align="center"><sub>The island, desktop widgets and the dock</sub></td>
    <td align="center"><sub>The expanded island</sub></td>
  </tr>
</table>

## Install

| | Supported | Tested with |
| --- | --- | --- |
| Plasma | 6.7 and 6.8 | 6.7.5, 6.8.0 |
| Qt | 6.10 or later | 6.11, 6.12 |
| KDE Frameworks | 6 | 6.31 |
| Kvantum (Glassy) | 1.1 | 1.1.8 |
| Session | Wayland | Wayland; X11 is untested |
| Distribution | Arch Linux, CachyOS; others untested | CachyOS. Elsewhere, install Kvantum and Aurorae first for Glassy; without them the installer skips Glassy |

It also needs Python 3, `kpackagetool6` and `qdbus6`. The island is built on Plasma's own
components (plasma-nm, plasma-pa, bluez-qt, PowerDevil, libksysguard), and `install.sh` warns
about any that are missing. KDE Connect and `powerprofilesctl` are optional.

For media playing in a browser, install the
[Plasma Browser Integration](https://community.kde.org/Plasma/Browser_Integration) extension
in the browser (and the `plasma-browser-integration` package): without it a browser often
reports no position, length or cover, and the player may not open the right tab.

```sh
git clone https://github.com/Contraill/Nothing-Kde-Theme.git
cd Nothing-Kde-Theme
./install.sh                  # install or upgrade
./install.sh --apply-layout   # set up the two panels, backing up the old layout first
./install.sh --widgets-only   # the desktop widgets only
./uninstall.sh                # remove everything Nothing KDE installed
```

Then choose **Nothing KDE** or **Nothing KDE Light** in System Settings. What the installer
changes, where it keeps the earlier state and how each part is undone:
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Releases, with every package and its checksum,
are on the [releases page](https://github.com/Contraill/Nothing-Kde-Theme/releases).

## Island and dock

The island shows workspaces, weather, the clock, the player and live activities: file
transfers, a microphone-in-use dot and the phone's battery. Volume and microphone changes
briefly take the clock's place. Expanded, it holds Wi-Fi, Bluetooth, sound, brightness, the
player, power profiles, system stats and notifications; a card's chevron, or a right-click,
opens its details. Any part of the compact island can be hidden.

- **Player:** clicking the cover opens the player's window. A YouTube video that comes
  without a cover gets its thumbnail from YouTube's image server.
- **Weather:** click it to choose a city. The data is from [Open-Meteo](https://open-meteo.com/)
  (CC BY 4.0), which receives the city and your IP address; no API key is needed.
- **Settings:** the gear opens the island's settings (a right-click, System Settings): light,
  dark or automatic at sunrise and sunset, the accent colour, the system tray, accent links
  and whether power actions ask first.
- **Dock:** Meta+1 … Meta+9 open or cycle its applications, the wheel cycles an application's
  windows, files dropped on an icon open in it and a drag reorders. Icons show unread badges,
  transfer progress and a dot for windows on another desktop; a middle-click on a preview
  closes that window.

With automatic wallpaper on, Nothing keeps its light and dark wallpapers on every screen that
has none of its own; your own images are left alone.

## Desktop widgets

Add them through **Add Widgets**. Clocks, date, weather, media and photo are adapted from
nothing-kde-widgets; the rest are Nothing KDE originals.

| Widget | What it shows |
| --- | --- |
| Analog, Digital and World, Large Clock | the time; the large clock has ten faces, from dotted and serif to blocks, bubbles and outline |
| Date | a page that turns to a calendar (classic, dots or numbers), or a pill that turns to its week |
| Weather | the forecast, as pages or circles (Open-Meteo) |
| Media | the playing track as cover pages, a player or a pill |
| Photo | your picture in a frame, a circle or a wide pill |
| System Monitor | the CPU, GPU, memory and disk you pick, as dot rings, dotted bars, a pill or one gauge; a sleeping graphics card is never woken to be read |
| Devices | the batteries of this computer, KDE Connect phones and Bluetooth devices, as dot rings or filled circles |
| Quick Toggles | the ones you pick of Wi-Fi, Bluetooth, airplane mode, sound, microphone, do not disturb, night light, coffee mode, power profile and hotspot, over a volume bar |
| Note | a note that saves as you type, or a rotating mantra |
| Focus Timer | a pomodoro that survives restarts and rings with Plasma's timer sound |
| Progress | the year as a dot ring, day-to-year bars, or a countdown to midnight |
| Greeting | good morning, afternoon or evening, with or without the time |
| Uptime | how long the computer has been on, day by day through the week |
| Visualizer | bands that move with the sound |
| Glyph | one light of a glyph interface (ring, arc, strip, line, dot, corner, dot ring) that flashes on the beat; any number of them play one show together |
| Glyph Matrix | a round 25 × 25 dot matrix to draw on, with a clock, animations, or a picture or GIF |
| Pet | a dot-matrix cat, dog, hamster or robot peeking over the edge |

Each widget's settings show its styles as cards with previews, and one shared row for the
theme (dark, light or KDE's), monochrome, the system accent and, where it fits, no card at
all. Many styles are designs from [EveryThing-UI](https://github.com/Prince-1652/EveryThing-UI)
(Prince-1652, MIT), redrawn with our own faces.

## Boot, login and sounds

```sh
./install.sh --boot-splash install       # the Plymouth boot animation (or remove)
./install.sh --login-wallpaper dark      # Plasma Login Manager's wallpaper (light, remove)
./install.sh --sounds import ~/glyph     # your own recordings as a sound theme
./install.sh --sounds use nothing        # or personal | default
```

The splash and the boot animation share one ring of dots in the KDE accent. When the accent
changes, the boot animation is redrawn and the initramfs rebuilt in the background, through a
polkit rule that allows that and nothing else. The login wallpaper is a wallpaper-only
drop-in: settings in `/etc/plasmalogin.conf` still win, and SDDM is not touched.

The **Nothing KDE** sound theme is synthesised dots, no recordings. Your own recordings, for
example from Glyph Composer, are named after the event (`message-new-instant.wav`) or an alias
(`notification`, `alarm`, `charging`, `connect`, …) and stay in `~/.local/share/sounds`.

## Glassy

A Kvantum theme and an Aurorae window decoration that follow KDE's colours and work with any
theme. Choose `Kvantum` as the application style, `Glassy` in Kvantum Manager and `Glassy` as
the window decoration, then tune them in **Glassy Settings**. Palette changes reach running
applications live ([notes](assets/kvantum/README.md)); Qt Quick pages, GTK and Electron are
outside Kvantum's reach.

```sh
./install.sh --appearance install   # or sync | disable, which restores your previous choices
```

## Accent links

```sh
./install.sh --accent-links enable starship   # spaceship | fastfetch | gtk | kitty
./install.sh --accent-links disable all
./install.sh --dolphin apply                  # or restore
```

The KDE accent reaches Starship, Spaceship, Fastfetch, libadwaita applications, Kitty's
automatic light and dark themes and Dolphin. Each link keeps your own configuration and backs
it up in `~/.config/nothing-kde/`; `--accent-links status` shows what is linked. Limine is
only exported to a file (`--accent-links export limine --source … --output …`). No icon theme
is installed; [Colloid](https://github.com/vinceliuice/Colloid-icon-theme) fits well.

## Notifications and privacy

```sh
./install.sh --notifications-only --restart-plasma   # the Glyph notification look
./notification-skin/rollback-native.sh               # back to KDE's
./install.sh --privacy-helper install                # camera off without a password
```

The notification look is installed only when Plasma's notification code matches what it
expects (the check needs a C++ compiler and Qt headers); otherwise KDE's own stays. The
island's camera button blocks USB cameras, and turning one back on always asks for the
password. The microphone button mutes the default input.

**Before uninstalling**, lift the command-line ALSA microphone block if you used it:
`pkexec /usr/bin/python3 -I "$PWD/runtime/privacy.py" microphone on`.

## Test and package

```sh
./validate.sh   # lint, QML and Python tests
./package.sh    # artifacts in dist/
```

The widgets are rendered with real Plasma, every style in dark and light, off screen:

```sh
cmake -S tests/widget-render -B /tmp/widget-render && cmake --build /tmp/widget-render
python3 tests/check-widgets.py --renderer /tmp/widget-render/nothing-kde-widget-render \
  --screenshots /tmp/widget-shots
```

Translations are gettext catalogs in `po/panel` and `po/widgets`; run `python3 po/build.py`
after editing them, and add a language as a new `<lang>.po`.

[CI](.github/workflows/ci.yml) runs all of this on every push and pull request: the packages,
`validate.sh` with the packages included, the translations and every widget style.

**Releases.** One [VERSION](VERSION) file holds the version, in
[Semantic Versioning](https://semver.org/) (`-rcN` for release candidates); changes are kept
in the [changelog](CHANGELOG.md). To release, write the version and the changelog's section,
then push a tag; CI checks the tag against VERSION and publishes the packages:

```sh
python3 packaging/set-version.py 1.1.0      # VERSION and every package's metadata
git commit -am "Release 1.1.0" && git tag v1.1.0 && git push origin main v1.1.0
```

## Credits

- The island began as Omar's Nothing Island (`org.omar.nothingisland`, MIT); its layout
  ideas remain ([notice](plasmoids/com.nothingplasma.panel/contents/island/NOTICE.md)).
- The clocks, date, weather, media, photo and the device circle are adapted from
  [nothing-kde-widgets](https://github.com/jaxparrow07/nothing-kde-widgets) by jaxparrow07.
- Many widget styles and the pets are designs from
  [EveryThing-UI](https://github.com/Prince-1652/EveryThing-UI) by Prince-1652
  ([MIT](widgets/shared/EveryThing-UI-LICENSE.txt)).
- Fonts: [Space Grotesk](https://github.com/floriankarsten/space-grotesk),
  [Bitcount](https://github.com/petrvanblokland/TYPETR-Bitcount) (as Nothing Dots) and
  [Fraunces](https://github.com/undercasetype/Fraunces) (as Nothing Serif) under the SIL OFL
  1.1, and Google's [Material Symbols](https://github.com/google/material-design-icons)
  under Apache 2.0.
- KDE: the island runs on Plasma's own components, the notification look on Plasma's
  notification code, and browser media on
  [Plasma Browser Integration](https://community.kde.org/Plasma/Browser_Integration).
- Weather data by [Open-Meteo](https://open-meteo.com/) (CC BY 4.0).

Each widget's `UPSTREAM-NOTICE.md` and [widgets/UPSTREAM.json](widgets/UPSTREAM.json) record
what was taken from where. This is not an official Nothing product.

## License

[GPL](LICENSE).
