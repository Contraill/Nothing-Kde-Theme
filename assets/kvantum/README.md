# Glassy — integration notes

Application Style **Kvantum**, Kvantum theme **Glassy**, native Aurorae decoration
**Glassy**. Kvantum remains a production dependency; no replacement engine,
daemon, whole-window opacity rule, or application injection is installed.

The SVG geometry is original. `runtime/appearance_render.py` materializes colors
from KDE palette roles; `Glassy.kvconfig` contains no Nothing color constants.
Window surfaces are 50%, menus 75%; editable controls retain an opaque Base.
Dolphin transparency uses Kvantum's own `transparent_dolphin_view` compatibility.

## Important limits / Önemli sınırlar

**Full live switching is not production-ready.** Native Qt palettes do update
in running Dolphin/Kate. Eleven unnecessary GeneralColors overrides have been
removed; only Base/AlternateBase startup compatibility remains. However, Kvantum
1.1.8 separately caches its standardPalette and SVG. Even with frozen asset files,
body surfaces keep the initial color. Some text/control rendering also stays
cached. Restart is not treated as a final solution; no automatic app/style/session
restart is implemented. See the [same-process audit](LIVE-PALETTE.md) for measured
live roles, remaining asset writes, and upstream limitations.

**Qt paleti canlı değişiyor; tüm Glassy çizimi henüz değişmiyor.** Gereksiz renk
override'ları kaldırıldı. Uygulamayı yeniden açmak final çözüm olarak kabul edilmiyor.

Aurorae owns decoration pixels, not the client's content. **Round bottom corners**
(default on) reserves a bottom decoration strip derived from the same Corner radius.
All four outer corners use that radius; turning it off restores square lower
corners and the thin bottom border. Client content is resized, never covered.
Maximized/tiled corners stay square. Aurorae 6.7 overrides the blur region when
maximized, so its blur toggle only works on restored/tiled decorations. No
misleading maximized-rounding switch is exposed. Global blur strength is untouched.
Alt uygulama köşeleri Aurorae tarafından kesilemez; tam büyütülmüş pencerede
bulanıklık bölgesini engine belirler. Bu sınırlar ayar açıklamalarında da belirtilir.

System Settings' Qt Quick content, GTK and Electron are outside Kvantum's scope.
Kate's editor and Qt input/view surfaces may intentionally remain opaque.

## Native Glassy configuration

Control density uses bounded padding plus Kvantum's documented `font` minimum
heights; Qt supplies font/icon metrics and device scaling. Compact/Normal/Comfortable
never depend on window or monitor dimensions. SVG slice widths/radii are unchanged.
Normal's extra vertical padding is 2 logical pixels (menu rows: 1). There is no
invented `max_height` key or fixed height cap that could clip larger accessibility
fonts; the maximum applies to extra density padding, not to application content.

The shared native form has Application / Glass / Window Decoration / Controls tabs.
The standalone **Glassy Settings** utility adds **Reset to Glassy defaults**, then Apply;
Aurorae's existing KCM exposes the same form and its native Defaults action.
All values use `[org.glassy.decoration]` in `auroraerc` and defaults/ranges in `main.xml`.
The form and QML defaults are generated together; no duplicated preset defaults.

Application settings: window and popup opacity (10–100%, Kvantum's supported range),
surface blur, Square/Subtle/Rounded control and popup corners, density, border strength,
scrollbar size and accent intensity. Accent intensity mixes rendered focus/selection
surfaces; it never changes KDE's saved accent. Original density/opacity defaults remain.
Decoration additions: Left/Center titles, Normal/Dimmed inactive buttons and an optional
subtle palette-accent active border. Existing decoration settings remain available.
Apply updates native decoration settings live and materializes Kvantum assets; cached
Kvantum instances still have the limitations in the audit. No applications are restarted.

## Geometry and popup polish

Background clipping, inside border and shadow now use circular paths with a shared
outer radius. The stroke centerline radius is `R - width/2`, not the old unrelated
quadratic curve. The KSvg blur mask uses `R - 1` for Aurorae's documented (+1,+1)
QRegion inset, preserving the same circle centers. Integer blur masks are not alpha masks.

Missing `menu-shadow-*` assets previously fell back to Kvantum's default menu artwork.
Original menu and tooltip shadow frames/hints now match the 1px low-contrast palette
border and corner geometry. Combo popups use Kvantum's documented menu presentation.

## Decoration defaults

System Settings → Window Decorations → Glassy → Configure.
The bundle installs English source labels and a Turkish catalog.

| Setting | Default |
| --- | --- |
| Corner radius (shared by top and enabled bottom corners) | 10 px (0–24) |
| Active / inactive opacity | 50% / 50% |
| Blur request | On, subject to the maximized limitation above |
| Border / separator | 1 px subtle / Off |
| Titlebar / button size / spacing | Normal |
| Shadow | Subtle |

`contents/config/main.xml` is the sole default-value source. Build/installation
generates `ConfigDefaults.js` and the native KSvg mask atlas from it. Values live
under `[org.glassy.decoration]` in `auroraerc`; Apply updates existing decorations.
No C++ decoration plugin is shipped.
The small C++ executable is only a QUiLoader/KConfig settings dialog, not a renderer,
plugin or daemon. Aurorae's Apply callback invokes the existing asset helper; the
standalone dialog does the same. Source builds reuse the installed Qt/KDE libraries.

The invisible mask FrameSvg uses its own alpha channel. KSvg 6.30's separate
`mask-*` cache does not invalidate when only the element prefix changes; avoiding
that redundant layer keeps radius and blur-off changes effective. The native
QRegion test exercises 0→24→0, resize and blur off/on on the same renderer.

## Ownership and distribution

`./install.sh --appearance install|sync|disable|uninstall|status` manages only our
assets and selections. Unchanged files are not rewritten. User-edited assets and
later user selections are preserved; plugin/theme pairs are restored together.
Original style, decoration, and scheme are recorded before installation. Color
schemes are only rolled back when an explicit Nothing switch was recorded.
Dependency providers are checked with pacman; Qt5 support is explicit (`--qt5`).
No dependency packages are removed, including those installed by the bundle.

The source bundle installs all components. The decoration archive is a native
`KWin/Decoration` KPackage; use `kpackagetool6 --type KWin/Decoration --install`.
Both required entrypoints (`code/main.qml` for KPackage, `ui/main.qml` for
Aurorae 6.7) instantiate the same `GlassyDecoration` component.
The system's SVG-only Aurorae Get New Stuff target is not a QML package installer.
Store-only global-theme download does not install system Kvantum dependencies.

## Verification

The Qt6 gallery covers Widgets, views, menus, dialogs, tooltips and state matrices.
The SVG probe asserts exact bounds for all frame states. The native config test
uses the same QUiLoader/KConfigLoader/KConfigDialogManager path as Aurorae's KCM.

```sh
cmake -S tests/glassy -B /tmp/glassy-checks
cmake --build /tmp/glassy-checks
QT_STYLE_OVERRIDE=kvantum /tmp/glassy-checks/glassy-gallery
QT_QPA_PLATFORM=offscreen /tmp/glassy-checks/glassy-mask \
  "$HOME/.local/share/kwin/decorations/org.glassy.decoration/contents/assets/masks.svg"
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_appearance.py
```

Wayland checks are opt-in (`tests/glassy-session-check.py`, `tests/glassy-apps.py`)
and restore test appearance settings. Captures/builds stay outside the source tree.
Do not treat offscreen rendering as a compositor/blur test.

2026-09-14 verification (Plasma 6.7.5 / Wayland, Kvantum 1.1.8, KSvg 6.30):
104 Python and 54 QML tests passed, including native package installation.
Frame bounds, native configuration binding and masks passed; masks also passed
at 125%, 150% and 200% scaling. Fresh Dolphin/Kate light and dark captures have
50% window surfaces and 100% whole-window opacity. A checkerboard test window
confirmed compositor blur behind both body and titlebar without changing wallpaper.
System Settings' QML content remains opaque. The same-process Light→Dark→Light
test **fails** (old surface/new palette), as described above. Reinstall preserved
asset mtimes and reused installed dependencies. This is not a complete acceptance
pass or a claim that all toolkit/state combinations are production-ready.

The visual-polish pass additionally checked radius 0/10/24 with borders 0/1/2,
resize, maximize/restore and left/right tiling in light and dark mode. Semantic
presets were exercised at 125% and 150%; configuration defaults/reset and native
Apply binding passed. Reinstall retained content and mtimes for all 20 owned
assets. The same-process Dolphin/Kate/System Settings/Kitty regression retained
the accent across panel reload and Light→Dark→Light; Kitty switched its body
colors without changing kitty.conf. This does not remove the Kvantum cache limit
above. Physical logout/reboot and a complete inactive-window visual matrix were
not performed in this pass.

Verified upstream contracts: [Kvantum theme format](https://github.com/tsujan/Kvantum/blob/V1.1.8/Kvantum/doc/Theme-Config),
[Aurorae 6.7.5 configuration and blur](https://github.com/KDE/aurorae/blob/v6.7.5/v1/aurorae.cpp),
[native configuration loader](https://github.com/KDE/aurorae/blob/v6.7.5/config/auroraeconfig.cpp),
[KSvg alpha-mask generation](https://github.com/KDE/ksvg/blob/v6.30.0/src/ksvg/framesvg.cpp),
[Plasma same-style reload policy](https://github.com/KDE/plasma-integration/blob/Plasma/6.7/qt6/src/platformtheme/khintssettings.cpp).
