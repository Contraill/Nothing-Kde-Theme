// Glassy: shared native Aurorae component for the runtime and KPackage entrypoints.
import QtQuick
import org.kde.kwin.decoration
import org.kde.ksvg as KSvg
import org.kde.plasma.plasma5support as PlasmaSupport
import "ConfigDefaults.js" as Config
import "Geometry.js" as Geometry

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
            values.SurfaceRoundness,values.UiDensity,values.BorderStrength,values.ScrollbarSize,values.AccentIntensity]);
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
        Canvas {
            anchors.fill: parent; anchors.margins: -root.shadowSize
            visible: !root.screenAdjacent && root.settings.Shadow > 0
            readonly property var paintState: [root.cornerRadius,root.roundBottom,root.settings.Shadow,decoration.client.active]
            onPaintStateChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const c=getContext("2d"); c.reset(); c.lineWidth=1;
                for (let i=0;i<root.shadowSize;i++) {
                    c.strokeStyle=Qt.rgba(0,0,0,[0,.10,.16,.23][root.settings.Shadow] *
                        (decoration.client.active ? 1 : .65) * (1-i/root.shadowSize));
                    Geometry.path(c,width,height,root.cornerRadius+root.shadowSize,root.shadowSize-i-.5,root.roundBottom);
                    c.stroke();
                }
            }
        }
        Item {
            id: titleHitArea
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: root.titleHeight
        }
        Canvas {
            id: outline
            anchors.fill: parent
            readonly property var paintState: [root.ink, root.surface, root.surfaceOpacity, root.cornerRadius, root.roundBottom, root.bottomHeight, root.edgeWidth, root.settings.Separator, root.titleHeight, root.settings.ActiveAccentBorder, decoration.client.active, colors.highlight]
            onPaintStateChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const c=getContext("2d"); c.reset();
                const b=root.edgeWidth;
                // Clip only the decoration region; never fill client content.
                c.save(); c.beginPath();
                c.rect(0,0,width,root.titleHeight);
                c.rect(0,root.titleHeight,b,height-root.titleHeight);
                c.rect(width-b,root.titleHeight,b,height-root.titleHeight);
                c.rect(b,height-root.bottomHeight,Math.max(0,width-2*b),root.bottomHeight); c.clip();
                Geometry.path(c,width,height,root.cornerRadius,0,root.roundBottom);
                c.fillStyle=Qt.rgba(root.surface.r,root.surface.g,root.surface.b,root.surfaceOpacity);
                c.fill(); c.restore();
                if (b > 0) {
                    const ink=root.settings.ActiveAccentBorder && decoration.client.active ? colors.highlight : root.ink;
                    c.strokeStyle=Qt.rgba(ink.r,ink.g,ink.b,root.settings.ActiveAccentBorder && decoration.client.active ? .28 : .15);
                    c.lineWidth=b; c.lineJoin="miter";
                    Geometry.path(c,width,height,root.cornerRadius,b/2,root.roundBottom); c.stroke();
                }
                if (root.settings.Separator) {
                    c.strokeStyle=Qt.rgba(root.ink.r,root.ink.g,root.ink.b,.12); c.lineWidth=1;
                    c.beginPath(); c.moveTo(b,root.titleHeight-.5); c.lineTo(width-b,root.titleHeight-.5); c.stroke();
                }
            }
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
