# Glassy: live palette audit

2026-09-14 · Plasma 6.7.5 / Wayland · Kvantum 1.1.8 / Qt 6.11.

This is **not** a report claiming that full live switching has been solved.
Refactor verification: 94 Python tests and 41 QML tests passed.

## What came from our implementation

The previous `appearance.py sync` regenerated both `Glassy.svg` and
`Glassy.kvconfig` on every color transition. `GeneralColors` contained RGB values
for 13 KDE palette roles, so the previous test was not measuring a palette-only
transition.

The refactor removed 11 unnecessary overrides: window, button, text, window text,
button text, highlight, highlighted text, tooltip text, disabled text, link, and
visited link. Per-control text colors are no longer specified either; Kvantum's
documented palette fallback is used. The native KDE `PaletteChanged` notification
also no longer depends on a file having been written. It is emitted even when only
text/link colors changed.

Only `base.color` and `alt.base.color` are still generated. This is based on an
observed Kvantum behavior rather than an assumption: in `standardPalette()`,
Kvantum explicitly falls back to white for a missing Base and derives a missing
AlternateBase from it. In the experiment where every color override was removed,
Base stayed `#ffffff` before the first palette notification. Keeping these two
roles prevents the white-content/readability regression on a dark first launch;
their values are still derived from KDE.

## Frozen-file experiment

`tests/glassy-live.py` launches real Wayland Dolphin and Kate processes under a
separate `XDG_CONFIG_HOME`, without touching user settings. The SVG/config assets
are generated once at startup and are **never modified** during the transitions.
Only the color scheme and KDE's native palette notification change.

The observer does not assign a palette/style or trigger repolish. PID and QStyle
address remain the same in all three stages, and the SHA-256 values of both assets
remain unchanged. Kate opens a real text file but does not edit it. Only processes
created by the test are closed when the experiment ends; this is not a production
workaround.

| Measurement in the same Dolphin/Kate processes | Light | Dark | Light |
| --- | --- | --- | --- |
| QApplication Window | `#f6f6f3` | `#090909` | `#f6f6f3` |
| QApplication WindowText | `#121212` | `#f5f5f5` | `#121212` |
| Kvantum standardPalette Window | light | **stayed light** | light |
| Painted glass surface | light, alpha 127 | **stayed light**, alpha 127 | light, alpha 127 |

The inverse test starting in dark mode also kept the surface dark through all
three stages. The refactored two-role version starts correctly with Base `#111111`
on a dark first launch.

This experiment shows that the main surface issue is not only an SVG file-cache
problem.

## What is and is not live

| Component | Status |
| --- | --- |
| Qt application and widget palette roles | Update in the same process; verified for Window/Text/Base/Button/Highlight roles. |
| Content that reads the Qt palette directly | Can update; Dolphin Places/label palettes and Kate editor content were checked. |
| Rendering of all text and icons | **Not universally live.** Some Kvantum menu/toolbar drawing or application-defined fixed colors can remain stale. A changed palette value does not imply that every pixel has changed. |
| Glass window/dialog background | Uses Kvantum's cached `standardPalette()` color; it does not update live while the same style object remains active. |
| SVG control fill, border, arrow/glyph, progress, and selected-item background | Static SVG; a Qt palette notification does not recolor the SVG. |
| KWin blur / alpha | Independent of color; surface alpha stayed 127 and whole-window opacity stayed 1. This experiment did not change blur strength. |
| Glassy Aurorae | Continues to use its separate SystemPalette path; this refactor does not change the decoration. |

## Why file generation could not be removed completely

`Glassy.kvconfig` now changes only when Base/AlternateBase changes. File writes are
not needed for Window/text/accent/link colors. The two remaining roles cannot be
removed safely until the initial-Base regression is solved.

`Glassy.svg` still needs recoloring for the current opaque control fills and glyphs.
Kvantum uses `QSvgRenderer`, not KSvg's Plasma palette classes, and the Qt palette
is not passed into the SVG renderer. Making the entire SVG transparent or using
`interior=false` does not guarantee a generic Qt-palette fill; some controls then
receive no fill at all. That would break the opaque/readable-control requirement,
so it was not adopted.

The production `sync` path therefore still updates the required SVG and the two
Base roles. Writes happen only when content actually differs. Updated assets are
loaded by newly created style objects, but they do not automatically reload inside
running processes.

The safe native-config/SVG refactor is complete at this stage. A complete solution
would require the same Kvantum backend to refresh its cached `standardPalette` on
palette changes and provide a supported palette-aware drawing path for SVG surfaces.
No external engine, dependency fork, application restart, session restart, or
temporary Breeze→Kvantum style switch was added.

## Reproduction and sources

### Context-menu follow-up — 2026-09-15

`tests/check-density.py` together with `glassy-density` measures isolated,
offscreen Light → Dark → Light palette events with a real Kvantum/QMenu.
The config contains only the production Base/AlternateBase overrides; Window/Text
are not pinned.

While the QMenu Window palette changes
`#f6f6f3 → #16191f → #f6f6f3`, the painted menu surface remains `#f6f6f3`
through all three stages. A newly created QMenu at every stage paints the same
stale surface as well. This shows that the behavior comes from Kvantum's style/SVG
cache path rather than one old QMenu object being retained by the application.

The render source still derives the menu color from the correct `window` palette
role, so production color/sync behavior was not changed. This test is not a
compositor-blur verification. No style switch, repolish, or running-application
restart workaround was added.

Density matrix:
8/10/14 pt × 100/125/200% × three densities × light/dark = 54 states.

At 10 pt Normal, button/input/combobox changed from 32→28 logical pixels, tabs
34→30, and menu rows 34→28. Font lower bounds, `sizeHint` stability across resize,
and theme parity passed.

Reproduce that measurement after building the `glassy-density` target:

```sh
cmake --build <build> --target glassy-density
python3 tests/check-density.py --probe <build>/glassy-density
```

### Runtime/state follow-up — 2026-09-14

`tests/runtime-live.py` checks Dolphin, Kate, System Settings, and Kitty in the real
session using the same processes through Light → Dark → Light, then restores the
previous accent and scheme.

The temporary `#806EE7` accent survived a panel-service reload, fresh startup helper
processes, and all three transitions. A real logout/reboot was not performed in
that particular pass. Picker Apply/Cancel/reopen behavior and a late backend reply
were verified by QML tests.

Kitty kept the same PID: its body changed
`#f6f6f3 → #090909 → #f6f6f3`; the main config SHA-256 stayed unchanged, all
16 ANSI colors stayed unchanged, and the existing opacity 0.5 / blur 1 settings
were preserved. Qt application palette roles updated live; the cached Kvantum
surface limitation described above did not change.

In production, a native notification is shown only on a real light/dark transition
when loaded Kvantum processes are present. Repeated notifications are deduplicated;
startup and accent-only syncs remain silent. No application or session restart was
added. Test processes are the only processes closed by the test.

```sh
cmake -S tests/glassy -B /tmp/glassy-checks
cmake --build /tmp/glassy-checks
python3 tests/glassy-live.py --variant refactored \
  --observer /tmp/glassy-checks/libglassy-live-capture.so \
  --output /tmp/glassy-live-new-run
# Full omission: --variant omit-all; inverse transition: --initial-mode dark
```

Use a new output directory for each run. The JSON output contains application/widget
palettes, the cached `standardPalette`, and a sample of the actually painted surface.

Upstream references:

- [Theme-Config, color inheritance exception 2](https://github.com/tsujan/Kvantum/blob/V1.1.8/Kvantum/doc/Theme-Config)
- [polishing.cpp: polish(QPalette), standardPalette, and Base fallback](https://github.com/tsujan/Kvantum/blob/V1.1.8/Kvantum/style/polishing.cpp)
- [Kvantum.cpp: PE_Widget and control-fill paths](https://github.com/tsujan/Kvantum/blob/V1.1.8/Kvantum/style/Kvantum.cpp)
- [rendering.cpp: QSvgRenderer and text fallback](https://github.com/tsujan/Kvantum/blob/V1.1.8/Kvantum/style/rendering.cpp)
