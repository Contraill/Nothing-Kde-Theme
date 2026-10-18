// Glassy: shared native Aurorae component for the runtime and KPackage entrypoints.
import QtQuick
import QtQuick.Shapes
import org.kde.kwin.decoration
import org.kde.ksvg as KSvg
import org.kde.plasma.plasma5support as PlasmaSupport
import "ConfigDefaults.js" as Config

Decoration {
    id: root
    property var settings: Config.defaults
    readonly property int shadowSize: 12
    readonly property bool screenAdjacent: decoration.client.maximized || decoration.client.adjacentScreenEdges !== 0
    readonly property int cornerRadius: screenAdjacent ? 0 : settings.CornerRadius
    readonly property int edgeWidth: screenAdjacent ? 0 : settings.BorderWidth
    readonly property bool roundBottom: !screenAdjacent && settings.RoundBottomCorners
    readonly property int bottomHeight: Math.max(edgeWidth, roundBottom ? cornerRadius : 0)
    readonly property int buttonExtent: [24, 28, 32][settings.ButtonSize]
    readonly property int titleHeight: Math.max([28, 34, 40][settings.TitlebarSize], buttonExtent + 4, options.titleFont.pixelSize + 10)
    readonly property int buttonGap: [0, 2, 5][settings.ButtonSpacing]
    readonly property real surfaceOpacity: (decoration.client.active ? settings.TitlebarOpacity : settings.InactiveOpacity) / 100
    readonly property color surface: colors.window
    readonly property color ink: colors.windowText
    property bool supportsMask: true
    property alias decorationMask: blurMask.mask
    // Native KCM Apply also materializes application presets, without a daemon.
    // Compare the semantic application values: KWin's ordinary reconfigure and
    // palette notifications must not recursively launch another synchronization.
    property string applicationFingerprint: ""
    property bool applicationSyncPending: false
    PlasmaSupport.DataSource {
        id: presetSync
        engine: "executable"
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }
    SystemPalette { id: colors; colorGroup: decoration.client.active ? SystemPalette.Active : SystemPalette.Inactive }
    DecorationOptions { id: options; deco: decoration }

    function syncApplicationSettings() {
        if (!applicationSyncPending || !decoration.client.active) return;
        applicationSyncPending=false;
        const helper=decodeURIComponent(Qt.resolvedUrl("../../../../../nothing-plasma/bin/appearance.py").toString().replace(/^file:\/\//,""));
        presetSync.connectSource("python3 '" + helper.replace(/'/g,"'\\''") + "' sync");
    }
    Connections { target: decoration.client; function onActiveChanged() { root.syncApplicationSettings(); } }

    function readSettings() {
        let values = {};
        for (const key in Config.defaults) {
            let value = decoration.readConfig(key, Config.defaults[key]);
            if (Config.limits[key]) value = Math.max(Config.limits[key][0], Math.min(Config.limits[key][1], Number(value)));
            values[key] = value;
        }
        const fingerprint=JSON.stringify([values.WindowOpacity,values.PopupOpacity,values.BlurSurfaces,
            values.SurfaceRoundness,values.UiDensity,values.BorderStrength,values.ScrollbarSize,values.AccentIntensity,
            values.OpaqueApplications]);
        if (applicationFingerprint && fingerprint !== applicationFingerprint) applicationSyncPending=true;
        applicationFingerprint=fingerprint;
        settings = values;
        syncApplicationSettings();
    }
    function updateMetrics() {
        borders.left = edgeWidth; borders.right = edgeWidth; borders.bottom = bottomHeight; borders.top = titleHeight;
        maximizedBorders.left = 0; maximizedBorders.right = 0; maximizedBorders.bottom = 0; maximizedBorders.top = titleHeight;
        extendedBorders.left = 5; extendedBorders.right = 5; extendedBorders.bottom = 5;
        padding.left = shadowSize; padding.right = shadowSize; padding.top = shadowSize; padding.bottom = shadowSize;
    }
    onTitleHeightChanged: updateMetrics()
    onEdgeWidthChanged: updateMetrics()
    onBottomHeightChanged: updateMetrics()
    Component.onCompleted: { readSettings(); updateMetrics(); decoration.installTitleItem(titleHitArea); }
    Connections { target: decoration; function onConfigChanged() { root.readSettings(); } }

    Item {
        id: frame
        anchors.fill: parent
        anchors.margins: decoration.client.maximized ? 0 : root.shadowSize
        // Scene-graph primitives only: Canvas kept a window-sized image per item and
        // repainted it on every frame of a resize.
        Item {
            id: shadow
            anchors.fill: parent; anchors.margins: -root.shadowSize
            visible: !root.screenAdjacent && root.settings.Shadow > 0
            readonly property real strength: [0, .10, .16, .23][root.settings.Shadow] * (decoration.client.active ? 1 : .65)
            // One 1 px ring per shadow pixel, fading outwards from the frame edge.
            Repeater {
                model: root.shadowSize
                Rectangle {
                    required property int index
                    readonly property real ringRadius: Math.min(root.cornerRadius + index + 1, width / 2, height / 2)
                    x: root.shadowSize - index - 1; y: x
                    width: shadow.width - 2 * x; height: shadow.height - 2 * y
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, shadow.strength * (1 - index / root.shadowSize))
                    topLeftRadius: ringRadius; topRightRadius: ringRadius
                    bottomLeftRadius: root.roundBottom ? ringRadius : 0; bottomRightRadius: bottomLeftRadius
                }
            }
        }
        Item {
            id: titleHitArea
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: root.titleHeight
        }
        Shape {
            id: surfaceShape
            anchors.fill: parent
            readonly property real outer: Math.max(0, Math.min(root.cornerRadius, width / 2, height / 2))
            ShapePath {
                // Odd-even fill leaves the client area out: decoration region only.
                fillRule: ShapePath.OddEvenFill
                fillColor: Qt.rgba(root.surface.r, root.surface.g, root.surface.b, root.surfaceOpacity)
                strokeWidth: -1
                PathRectangle {
                    width: surfaceShape.width; height: surfaceShape.height
                    topLeftRadius: surfaceShape.outer; topRightRadius: surfaceShape.outer
                    bottomLeftRadius: root.roundBottom ? surfaceShape.outer : 0; bottomRightRadius: root.roundBottom ? surfaceShape.outer : 0
                }
                PathRectangle {
                    x: root.edgeWidth; y: root.titleHeight
                    width: Math.max(0, surfaceShape.width - 2 * root.edgeWidth)
                    height: Math.max(0, surfaceShape.height - root.titleHeight - root.bottomHeight)
                }
            }
        }
        Rectangle {
            id: outline
            anchors.fill: parent
            visible: root.edgeWidth > 0
            readonly property bool accent: root.settings.ActiveAccentBorder && decoration.client.active
            readonly property color ink: accent ? colors.highlight : root.ink
            color: "transparent"
            border.width: root.edgeWidth
            border.color: Qt.rgba(ink.r, ink.g, ink.b, accent ? .28 : .15)
            topLeftRadius: surfaceShape.outer; topRightRadius: surfaceShape.outer
            bottomLeftRadius: root.roundBottom ? surfaceShape.outer : 0; bottomRightRadius: bottomLeftRadius
        }
        Rectangle {
            visible: root.settings.Separator
            x: root.edgeWidth; y: root.titleHeight - 1
            width: Math.max(0, parent.width - 2 * root.edgeWidth); height: 1
            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, .12)
        }
        ButtonGroup {
            id: leftButtons
            height: root.buttonExtent
            anchors.left: parent.left; anchors.leftMargin: root.screenAdjacent ? 0 : Math.max(4,root.cornerRadius / 2)
            anchors.verticalCenter: titleHitArea.verticalCenter
            spacing: root.buttonGap; explicitSpacer: root.buttonExtent / 3
            buttons: options.titleButtonsLeft
            closeButton: closeComponent; minimizeButton: minComponent; maximizeButton: maxComponent
            menuButton: menuComponent; appMenuButton: appMenuComponent
            keepAboveButton: aboveComponent; keepBelowButton: belowComponent
            allDesktopsButton: desktopsComponent; shadeButton: shadeComponent; helpButton: helpComponent
        }
        ButtonGroup {
            id: rightButtons
            height: root.buttonExtent
            anchors.right: parent.right; anchors.rightMargin: root.screenAdjacent ? 0 : Math.max(4,root.cornerRadius / 2)
            anchors.verticalCenter: titleHitArea.verticalCenter
            spacing: root.buttonGap; explicitSpacer: root.buttonExtent / 3
            buttons: options.titleButtonsRight
            closeButton: closeComponent; minimizeButton: minComponent; maximizeButton: maxComponent
            menuButton: menuComponent; appMenuButton: appMenuComponent
            keepAboveButton: aboveComponent; keepBelowButton: belowComponent
            allDesktopsButton: desktopsComponent; shadeButton: shadeComponent; helpButton: helpComponent
        }
        Text {
            anchors.left: leftButtons.right; anchors.leftMargin: 10
            anchors.right: rightButtons.left; anchors.rightMargin: 10
            anchors.top: parent.top; height: root.titleHeight
            text: decoration.client.caption; textFormat: Text.PlainText
            font: options.titleFont; color: root.ink
            horizontalAlignment: root.settings.TitleAlignment === 1 ? Text.AlignHCenter : Text.AlignLeft
            verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; clip: true
        }
    }
    // Aurorae consumes this native QRegion on each buffer update. Its 6.7
    // maximized path overrides it with a full region (documented in config UI).
    KSvg.FrameSvgItem {
        id: blurMask
        anchors.fill: parent; anchors.margins: 1
        imagePath: Qt.resolvedUrl("../assets/masks.svg")
        prefix: root.settings.Blur ? (root.roundBottom ? "b" : "r") + root.cornerRadius : "off"
        opacity: 0
    }
    component Button: GlassButton {
        ink: root.ink; hoverColor: root.ink
        opacity: !decoration.client.active && root.settings.InactiveButtons === 1 && !hovered ? .55 : 1
        width: root.buttonExtent; height: root.buttonExtent
    }
    Component { id: closeComponent; Button { buttonType: DecorationOptions.DecorationButtonClose } }
    Component { id: minComponent; Button { buttonType: DecorationOptions.DecorationButtonMinimize } }
    Component { id: maxComponent; Button { buttonType: DecorationOptions.DecorationButtonMaximizeRestore } }
    Component { id: menuComponent; Button { buttonType: DecorationOptions.DecorationButtonMenu } }
    Component { id: appMenuComponent; Button { buttonType: DecorationOptions.DecorationButtonApplicationMenu } }
    Component { id: aboveComponent; Button { buttonType: DecorationOptions.DecorationButtonKeepAbove } }
    Component { id: belowComponent; Button { buttonType: DecorationOptions.DecorationButtonKeepBelow } }
    Component { id: desktopsComponent; Button { buttonType: DecorationOptions.DecorationButtonOnAllDesktops } }
    Component { id: shadeComponent; Button { buttonType: DecorationOptions.DecorationButtonShade } }
    Component { id: helpComponent; Button { buttonType: DecorationOptions.DecorationButtonQuickHelp } }
}
