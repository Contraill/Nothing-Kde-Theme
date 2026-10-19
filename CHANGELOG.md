# Changelog

All notable changes. Versions follow [Semantic Versioning](https://semver.org/); release
candidates are `X.Y.Z-rcN`. The format follows [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-10-20

The first stable release, since 0.6.0-rc32.

### Added
- Nineteen desktop widgets in one look, each style a card with a preview: clocks, date,
  weather, media, photo, System Monitor (wake-free GPU), Devices, Quick Toggles, Note,
  Focus Timer, Progress, Greeting, Uptime, Visualizer, Glyph, Glyph Matrix and Pet.
- Island: live activities, a KDE Connect phone's battery, holidays and moon phases in the
  calendar, actionable notifications, player choice with shuffle and repeat, and a
  YouTube thumbnail when a browser sends no cover.
- Dock: Meta+1 … Meta+9, wheel cycling, file drops, unread badges and transfer progress.
- A Nothing KDE sound theme with personal recordings import, an accent-aware splash and a
  Plymouth boot animation.
- The KDE accent for libadwaita applications, and Plasma's automatic light/dark switching.
- Glassy: an always-opaque application list and three button styles.
- Our own large-clock faces (Nothing Dotted, Tiles and Stencil, SIL OFL 1.1) and a text
  cut of Nothing Serif for small sizes.
- CI: validation, widget rendering and packaging on every push; tagged releases publish
  the archives.

### Changed
- The island runs on Plasma's own backends: plasma-nm, plasma-pa, PowerDevil, bluez-qt
  and ksystemstats.
- Glassy reloads live by flipping between Kvantum's two style keys.
- Translations are gettext catalogs.
- One VERSION file; `packaging/set-version.py` writes it into every package.

### Fixed
- KWin's window menu showed black text on dark glass.
- The cover click now brings the player's window forward on Wayland.
- Long 12-hour times no longer overflow the large clock.
- The large clock's block faces no longer show a gap in the 1 and the 7 on the GPU.
- Uninstalling keeps the layout backups, in `~/.local/share/nothing-kde-backups`.
- The notification installer no longer reinstalls on every run where `diff` is missing,
  and with Qt 5 installed the tools and tests use Qt 6's qmlformat, qmllint and runner.

### Removed
- NType 82 and three unlicensed clock fonts; no bundled font is under restrictive terms.

## [0.6.0-rc32]

The last tag before this changelog; see the git history.
