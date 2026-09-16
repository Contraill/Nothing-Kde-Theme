# QML warning audit — 2026-09-15

Scope: Nothing/Glassy source, installed project-owned widgets, Qt 6.11.2,
Plasma 6.7.5. No logging filters, lint exclusions or warning suppression were added.

## Fixed project bugs

| Diagnostic | Root cause and correction |
| --- | --- |
| Large clock `font.pixelSize` binding loop at startup | `dateLabel.font.pixelSize → dateLabel.height → layout/text metrics → font.pixelSize`. Both date/time sizing now read the existing `Layout.preferredHeight` (10 px) reservation. Font families, sizing ratios, margins and alignment are unchanged. |
| Four undefined alignment enum accesses | Weather's wide hourly/daily forecasts used `Qt.AlignVTop`; the digital world clock used `Qt.AlignHLeft` twice. These enum members do not exist. Use `Qt.AlignTop` and `Qt.AlignLeft`. |
| Seventeen `Quick.layout-positioning` diagnostics | Six widget configuration pages assigned separator `height` while a layout owned geometry (16 occurrences). CompactPlayer also assigned the artist label's `height`. Use `Layout.preferredHeight` with the same values, leaving actual geometry to the layout. |
| Marquee `duplicate-property-binding` on `x` | `x: 0` and `SequentialAnimation on x` were simultaneous property owners. The sequence now uses explicit animation targets; the existing reset function still owns start/stop. Reset also follows text width changes, including font metrics, so growing text starts scrolling and shrinking text stops. |

The layout ownership rule is described in the [Qt Layout documentation](https://doc.qt.io/qt-6/qml-qtquick-layouts-layout.html).
Explicit animation targets follow [Qt SequentialAnimation](https://doc.qt.io/qt-6/qml-qtquick-sequentialanimation.html).

## Final UI regression follow-up

- Wide weather header: its child font/icon sizes read the layout's actual height,
  feeding their implicit sizes back into that layout. They now use its existing
  preferred height reservation. All 26 native widget variants render without
  recursive rearrangement, with Qt diagnostics explicitly routed to stderr.
- `check-photo.py` tests the new bundled image, legacy default migration and custom
  image path in light/dark through OpenGL. The Qt Quick software backend does not
  render MultiEffect, so its screenshot alone cannot verify photo visibility.
- Native test runners set `QT_FORCE_STDERR_LOGGING=1` so diagnostics are captured
  even on systems that normally route Qt messages to the journal. No messages
  are filtered out.
- WeatherSettings adds one static outer-ID scope diagnostic, covered by its
  locally instantiated overlay and native/QML rendering tests.

## Remaining runtime messages

| Message | Classification, evidence and limit |
| --- | --- |
| `Member visible … PlasmaQuick::Dialog overrides …` | Framework declaration warning, not a Nothing binding cycle. Installed `plasmaquick/dialog.h` redeclares QQuickWindow's visible property using `visibleChangedProxy`. Native Dialog placement remains functional after reload. |
| `Member enabled … DeclarativeDropArea overrides …` | Framework declaration warning. Installed `org/kde/draganddrop/draganddropplugin.qmltypes` declares enabled again on its QQuickItem-derived DropArea. No project property redeclaration was introduced. |
| `Connecting to deprecated signal QDBusConnectionInterface::serviceOwnerChanged` | Native dependency deprecation. Emitted by libQt6DBus; no project QML/Python/C++ code connects to that signal. Exact native caller was not attributed. It is not evidence of undefined QML state. |
| `QIODevice::read (QSslSocket): device not open` | Native network/transport diagnostic seen during session startup. No accompanying QML TypeError or binding loop. The particular network requester was not attributed, so this is not claimed as a fixed or universally harmless network condition. |
| `Cannot attach popup of unknown type` (earlier session log) | LayerShellQt transport warning. Its `QWaylandLayerSurface::attachPopup` rejects a surface role that cannot be cast to xdg_popup. The final UI follow-up reproduced it while opening the live launcher; the launcher rendered correctly without a project QML error. This does not prove every tray/application popup path. No popup redesign or suppression was made. [Upstream implementation](https://github.com/KDE/layer-shell-qt/blob/Plasma/6.7/src/qwaylandlayersurface.cpp). |
| Host portal `Connection already associated with an application ID` (earlier startup log) | Portal registration failure from the native session stack. No project code registers an application ID with the portal. Not reproduced on this run's reload. |

Framework declaration evidence: [Plasma Dialog](https://github.com/KDE/libplasma/blob/Plasma/6.7/src/plasmaquick/dialog.h)
and [KDeclarative DropArea](https://github.com/KDE/kdeclarative/blob/master/src/qmlcontrols/draganddrop/DeclarativeDropArea.h).

## Remaining static diagnostics

These are retained diagnostics, not ignore rules. Distinguish a source fragment
from the native runtime context that loads it.

| Diagnostic | Classification and checked dependency |
| --- | --- |
| Panel's 78 `unqualified` warnings | Creation-context accesses to enclosing IDs from inline components/delegates. Their owners instantiate them locally; no undefined access was observed. The complete original location inventory is below. Changing component binding semantics solely to lower this count would be unrelated refactoring. |
| Other `unqualified` warnings | Widget i18n/i18nc are provided by Plasma's localized engine context; delegate index/modelData and enclosing IDs come from their actual creation contexts. Tests supply their own TestCase/fixture context. Pinned notification fragments have a generated native context. These are static scope/compilation diagnostics, not observed property cycles. |
| `QObject` missing color members (74 accesses in broad source scan) | Shared components accept `required property QtObject colors`; their callers pass NothingColors, which defines the accessed members. The static QObject type does not expose these QML properties. All eight applet packages rendered without null/undefined color errors. |
| Digital clock `parent…isPillMode` (2 accesses) | Static parent type is QQuickItem. Actual digitalFullComponent parent defines isPillMode and owns both branches. Runtime variant rendering resolves the property. |
| Notification `import`, `unresolved-type`, `required`, `unresolved-alias` | Source fragments reference native notification resources and generated siblings that are absent in an unbuilt source-only scan. `prepare-native.py` assembles the pinned package. Upstream Globals/NotificationPopup are hash-checked inputs; no upstream source was edited. Preview.qml similarly expects the generated adapter. Native generator/package tests and live notification bridge startup pass. |
| Glassy `ConfigDefaults.js` import and two `missing-type` diagnostics | ConfigDefaults.js is generated from main.xml at packaging/install. KSvg's mask alias and DecorationOptions' native `deco` property also have incomplete static type descriptions. Source-only lint cannot substitute for the generated Aurorae package and KWin context. Package tests pass; the active Glassy decoration remains unchanged. |

Broad source scan included all standalone test fixtures and pinned/generated-input
fragments, beyond validate.sh's shipped panel scan. There were no QML API
`deprecated` diagnostics in that scan; the deprecation above is from native DBus.

### Panel location inventory

All rows below are `unqualified` creation-context diagnostics, not runtime errors.
Paths are relative to `plasmoids/com.nothingplasma.panel/contents/`.

| File | Source lines | Count |
| --- | --- | --- |
| `island/ui/AudioPanel.qml` | 169, 204 | 2 |
| `island/ui/CalendarPanel.qml` | 295, 300, 301, 323, 326, 327, 363, 365, 366, 404, 407, 415, 419, 430, 431, 444, 445 | 22 |
| `island/ui/ConnPanel.qml` | 240, 245, 246, 249, 264, 270, 286, 295, 299, 302, 333, 411, 454, 468, 588 | 17 |
| `island/ui/ExpandedPanel.qml` | 430, 431, 438, 444, 450, 457, 464, 471 | 8 |
| `island/ui/MediaCard.qml` | 69, 102, 116, 290, 313, 325, 327, 380, 381, 385, 386, 388 | 14 |
| `island/ui/MiniPlayer.qml` | 100, 119 | 2 |
| `island/ui/NotifPanel.qml` | 182 | 1 |
| `island/ui/PowerView.qml` | 112, 114, 116, 188, 228, 256 | 6 |
| `island/ui/QuickActions.qml` | 118 | 1 |
| `island/ui/Workspaces.qml` | 59, 60, 85 | 3 |
| `ui/components/NativeWindowThumbnail.qml` | 19, 24 | 2 |

## Verification and reproduction

- Full packaged validation: 128 Python tests, 102 Qt Quick tests, plus six native
  notification generator tests; no failures/skips. Panel lint retains 79
  scope warnings and has no blocking diagnostic.
- Clock: five fonts × date on/off × light/dark, each saved and reloaded in a fresh
  Plasma applet host with isolated KConfig. Five size samples per launch
  (300×200 → 400×200 → 600×300 → 400×400 → 300×200), including date-row toggles.
  All 200 visible geometry/font measurements match the previous source.
- The same resize sweep also ran in two real Wayland applet windows, light/dark,
  without a QML loop/error. The broader widget run rendered 26 variants/modes.
- Live plasmashell reload: clock loop gone, both Nothing panels present at their
  original 50 px height, notification bridge ready. The desktop scripting API
  did not apply requested live widget geometry changes; size coverage therefore
  comes from the actual native applet hosts above, not that no-op API call.
- Saved config is loaded into a fresh native applet process, covering the clock's
  configuration initialization path. A real user logout/login was not performed;
  compositor/session-manager login behavior is not claimed as tested.

Reproduce without repository artifacts:

```sh
cmake -S tests/widget-render -B /tmp/nothing-widget-check-build
cmake --build /tmp/nothing-widget-check-build
python3 -B tests/check-clock.py --renderer /tmp/nothing-widget-check-build/nothing-kde-widget-render --output /tmp/nothing-clock-check
python3 -B tests/check-photo.py --renderer /tmp/nothing-widget-check-build/nothing-kde-widget-render
python3 -B tests/check-widgets.py --renderer /tmp/nothing-widget-check-build/nothing-kde-widget-render --screenshots /tmp/nothing-widget-check
./package.sh --output /tmp/nothing-qml-dist
env -u STARSHIP_CONFIG NOTHING_PACKAGE_DIR=/tmp/nothing-qml-dist ./validate.sh
```

STARSHIP_CONFIG is unset only for the test process because the existing Starship
round-trip fixture expects the default prompt path. User settings are untouched.
The clock harness checks actual font metrics, alignment, color, resize round-trip,
and saved preferences across processes. The widget harness now fails on binding
loops, polish loops and recursive layout rearrangement as well as QML load errors.
