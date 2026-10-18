pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../island/ui" as Island

Item {
    id: root
    property real uiScale: 1
    property var appsModel
    property var runnerModel
    property var hiddenApps: []
    property var tasksModel
    property var panelConfig: null
    property bool active: false
    property color accentColor: Island.Theme.fg
    readonly property var pinnedLaunchers: tasksModel?.launcherList ?? []
    signal launched()
    signal pinRequested(string launcherUrl)
    signal settingsRequested()
    signal systemSettingsRequested()
    function launcherUrlFor(data) {
        const candidate = String(data?.favoriteId || data?.url || "");
        if (candidate && !candidate.includes(":") && candidate.endsWith(".desktop")) return "applications:" + candidate;
        return candidate;
    }
    function isPinned(data) {
        root.pinnedLaunchers;
        const url = launcherUrlFor(data);
        return url.length > 0 && tasksModel && tasksModel.launcherPosition(url) >= 0;
    }
    function activateFirst() {
        if (grid.count > 0 && grid.model) {
            const row = Math.max(0, grid.currentIndex);
            root.recordLaunch(grid.model.data(grid.model.index(row, 0), visibleApps.favoriteIdRole));
            grid.model.trigger(row, "", null);
            root.launched();
        }
    }

    // Launch counts kept in the panel configuration. KDE's activity statistics
    // would be the natural source, but they stop recording on some systems.
    property var mostUsed: []
    function usage() {
        try { return JSON.parse(root.panelConfig?.launcherUsage || "{}"); } catch (e) { return {}; }
    }
    function recordLaunch(favoriteId) {
        const id = visibleApps.identity(favoriteId);
        if (!id.endsWith(".desktop") || !root.panelConfig) return;
        const map = root.usage();
        const entry = map[id] ?? [0, 0];
        map[id] = [entry[0] + 1, Date.now()];
        root.panelConfig.launcherUsage = JSON.stringify(map);
    }
    function refreshMostUsed() {
        const model = root.appsModel;
        const map = root.usage();
        if (!model) { root.mostUsed = []; return; }
        const now = Date.now();
        const rows = [];
        for (let row = 0; row < model.count; ++row) {
            const index = model.index(row, 0);
            const id = visibleApps.identity(model.data(index, visibleApps.favoriteIdRole));
            const entry = map[id];
            if (!entry || root.hiddenApps.includes(id)) continue;
            // Launches fade with a 30-day half-life, so habits can change.
            const score = entry[0] * Math.pow(0.5, (now - entry[1]) / (30 * 86400000));
            rows.push({row: row, score: score, name: String(model.data(index, Qt.DisplayRole) ?? ""),
                       icon: model.data(index, Qt.DecorationRole), favoriteId: model.data(index, visibleApps.favoriteIdRole)});
        }
        rows.sort((a, b) => b.score - a.score);
        root.mostUsed = rows.slice(0, 8);
    }
    function launchMostUsed(item) {
        if (!root.appsModel) return;
        root.recordLaunch(item.favoriteId);
        root.appsModel.trigger(item.row, "", null);
        root.launched();
    }
    function resetSearch() { search.clear(); if (runnerModel) runnerModel.query = ""; }
    function focusDefault() { search.forceActiveFocus(); }
    onActiveChanged: {
        if (active) root.refreshMostUsed();
        if (active) Qt.callLater(() => search.forceActiveFocus());
        else resetSearch();
    }
    Component.onCompleted: if (active) Qt.callLater(() => search.forceActiveFocus());

    AppFilter {
        id: visibleApps
        inputModel: search.text.length > 0
            ? ((root.runnerModel && root.runnerModel.count > 0) ? root.runnerModel.modelForRow(0) : null)
            : root.appsModel
        hiddenApps: root.hiddenApps
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 16
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: Island.Cfg.t("APPLICATIONS")
                font.family: Island.Theme.fontDots
                font.pixelSize: 28 * root.uiScale
                color: Island.Theme.fg
            }
            QQC2.AbstractButton {
                id: settings
                objectName: "launcherSettingsButton"
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                Accessible.name: Island.Cfg.t("LAUNCHER SETTINGS")
                onClicked: root.settingsRequested()
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: root.systemSettingsRequested()
                }
                background: Rectangle { radius: 16; color: settings.hovered ? Island.Theme.surfaceHigh : Island.Theme.surfaceAlt }
                contentItem: Text {
                    text: "settings"
                    font.family: Island.Theme.fontIcons; font.pixelSize: 20
                    color: Island.Theme.fgDim
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
            }
        }
        QQC2.TextField {
            id: search
            objectName: "dockSearch"
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            placeholderText: Island.Cfg.t("SEARCH LAUNCHER")
            Accessible.name: placeholderText
            font.family: Island.Theme.font
            font.pixelSize: 13
            color: Island.Theme.fg
            placeholderTextColor: Island.Theme.fgDim
            selectByMouse: true
            leftPadding: 42
            rightPadding: 14
            background: Rectangle {
                radius: Island.Theme.shapeMd
                color: Island.Theme.surfaceAlt
                border.width: search.activeFocus ? 1 : 0
                border.color: Island.Theme.outline
                Text {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "search"; font.family: Island.Theme.fontIcons; font.pixelSize: 19
                    color: Island.Theme.fgDim
                }
            }
            onTextChanged: {
                if (root.runnerModel) root.runnerModel.query = text;
                grid.currentIndex = 0;
            }
            Keys.onReturnPressed: root.activateFirst()
            Keys.onEnterPressed: root.activateFirst()
            Keys.onDownPressed: { grid.forceActiveFocus(); grid.currentIndex = 0; }
        }
        // Most used applications.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: !search.text.length && root.mostUsed.length > 0
            Text {
                text: Island.Cfg.t("MOST USED")
                font.family: Island.Theme.font
                font.pixelSize: 10
                font.letterSpacing: 1.2
                color: Island.Theme.fgDim
            }
            Row {
                spacing: 6
                Repeater {
                    model: root.mostUsed
                    QQC2.AbstractButton {
                        id: favorite
                        required property var modelData
                        required property int index
                        readonly property string appName: modelData.name
                        visible: index < Math.max(1, Math.floor(grid.width / (52 * root.uiScale)))
                        width: 46 * root.uiScale
                        height: width
                        Accessible.name: appName
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: appName
                        onClicked: root.launchMostUsed(favorite.modelData)
                        background: Rectangle {
                            radius: Island.Theme.shapeMd
                            color: favorite.hovered || favorite.activeFocus ? Island.Theme.surfaceHigh : Island.Theme.surfaceAlt
                        }
                        contentItem: Item {
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 28 * root.uiScale
                                height: width
                                source: favorite.modelData.icon
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: search.text.length ? Island.Cfg.t("SEARCH RESULTS") : Island.Cfg.t("ALL APPS")
                font.family: Island.Theme.font
                font.pixelSize: 10
                font.letterSpacing: 1.2
                color: Island.Theme.fgDim
            }
            Text {
                text: grid.count
                font.family: Island.Theme.fontDots; font.pixelSize: 17
                color: Island.Theme.fgDim
            }
        }
        GridView {
            id: grid
            objectName: "dockAppGrid"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / Math.max(1, Math.floor(width / (100 * root.uiScale)))
            cellHeight: 96 * root.uiScale
            currentIndex: 0
            keyNavigationEnabled: true
            highlightMoveDuration: 120
            model: visibleApps
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
            Keys.onReturnPressed: root.activateFirst()
            Keys.onEnterPressed: root.activateFirst()
            Keys.onEscapePressed: event => { if (search.text.length) { root.resetSearch(); search.forceActiveFocus(); } else event.accepted = false; }
            // Typing while the grid has focus keeps searching instead of doing nothing.
            Keys.onPressed: event => {
                const modified = event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier);
                if (event.key === Qt.Key_Backspace) {
                    search.forceActiveFocus();
                    search.remove(Math.max(0, search.cursorPosition - 1), search.cursorPosition);
                    event.accepted = true;
                } else if (!modified && event.text.length && event.text.trim().length) {
                    search.forceActiveFocus();
                    search.insert(search.cursorPosition, event.text);
                    event.accepted = true;
                }
            }
            delegate: QQC2.AbstractButton {
                id: app
                required property var model
                required property int index
                readonly property string appName: String(model.display || model.name || "")
                readonly property string launcherUrl: root.launcherUrlFor(model)
                width: grid.cellWidth - 6
                height: grid.cellHeight - 6
                Accessible.name: appName
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: appName
                onClicked: { grid.currentIndex = index; root.activateFirst(); }
                background: Rectangle {
                    radius: Island.Theme.shapeLg
                    color: app.hovered || app.activeFocus || (grid.activeFocus && grid.currentIndex === app.index) ? Island.Theme.surfaceHigh : "transparent"
                    border.width: app.activeFocus || (grid.activeFocus && grid.currentIndex === app.index) ? 1 : 0
                    border.color: Island.Theme.outline
                }
                contentItem: Item {
                    Kirigami.Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 10
                        width: 32 * root.uiScale
                        height: width
                        source: app.model.decoration
                    }
                    Text {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.leftMargin: 5; anchors.rightMargin: 5; anchors.bottomMargin: 6
                        height: 30 * root.uiScale
                        text: app.appName
                        textFormat: Text.PlainText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.family: Island.Theme.font
                        font.pixelSize: 11 * root.uiScale
                        color: Island.Theme.fg
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 9
                        width: 4; height: 4; radius: 2
                        color: Island.Theme.fg
                        visible: root.isPinned(app.model)
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: menu.popup()
                }
                QQC2.Menu {
                    id: menu
                    font.family: Island.Theme.font
                    palette.text: Island.Theme.fg
                    palette.windowText: Island.Theme.fg
                    palette.buttonText: Island.Theme.fg
                    palette.highlightedText: Island.Theme.fg
                    palette.highlight: Island.Theme.surfaceTop
                    background: Rectangle { radius: Island.Theme.shapeMd; color: Island.Theme.surfaceHigh; border.width: 1; border.color: Island.Theme.outline }
                    QQC2.MenuItem {
                        text: Island.Cfg.t("OPEN APP")
                        onTriggered: { grid.currentIndex = app.index; root.activateFirst(); }
                    }
                    QQC2.MenuItem {
                        text: root.isPinned(app.model) ? Island.Cfg.t("UNPIN DOCK") : Island.Cfg.t("PIN DOCK")
                        enabled: app.launcherUrl.length > 0
                        onTriggered: root.pinRequested(app.launcherUrl)
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: grid.count === 0
                text: search.text.length ? Island.Cfg.t("NO APPS FOUND") : Island.Cfg.t("LOADING APPS")
                font.family: Island.Theme.font
                font.pixelSize: 13
                color: Island.Theme.fgDim
            }
        }
        Text {
            text: Island.Cfg.t("DOCK PIN HINT")
            font.family: Island.Theme.font
            font.pixelSize: 10
            color: Island.Theme.fgFaint
        }
    }
}
