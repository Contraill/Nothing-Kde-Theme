pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import "../../island/ui" as Island
import "RuntimePaths.js" as RuntimePaths
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

Item {
    id: root

    required property var shortcutController
    property var appsModel: null
    property var panelConfig: null
    readonly property var hiddenApps: panelConfig?.hiddenApplications ?? []
    function setAppVisible(identity, visible) {
        if (!panelConfig || !identity) return;
        const next = hiddenApps.filter(id => id !== identity);
        if (!visible) next.push(identity);
        panelConfig.hiddenApplications = next;
    }
    property real uiScale: 1.0
    property color accentColor: Kirigami.Theme.focusColor
    property bool metaEnabled: false
    property bool metaBusy: false
    property string metaStatus: Island.Cfg.t("CHECKING…")
    signal backRequested()

    NothingPalette { id: nothingPalette; accent: root.accentColor }
    Exec { id: exec }

    function helperCommand(args) {
        return RuntimePaths.command(Qt.resolvedUrl("../../tools/nothing-control.sh"), "nothing-control.sh", "bash", args)
    }

    function refreshMetaShortcut() {
        if (Island.Backend.preview || root.metaBusy) return
        exec.run(root.helperCommand("launcher-meta status"), function(r) {
            root.metaEnabled = r.exitCode === 0 && r.stdout.trim() === "on"
            root.metaStatus = r.exitCode === 0 ? (root.metaEnabled ? Island.Cfg.t("META KEY ENABLED") : Island.Cfg.t("META KEY DISABLED")) : Island.Cfg.t("META STATUS UNAVAILABLE")
        })
    }

    function setMetaShortcut(enabled) {
        if (root.metaBusy) return
        root.metaBusy = true
        root.metaStatus = enabled ? Island.Cfg.t("ENABLING META…") : Island.Cfg.t("DISABLING META…")
        exec.run(root.helperCommand("launcher-meta " + (enabled ? "on" : "off")), function(r) {
            root.metaBusy = false
            if (r.exitCode === 0) {
                root.metaEnabled = enabled
                root.metaStatus = enabled ? Island.Cfg.t("META KEY ENABLED") : Island.Cfg.t("META KEY DISABLED")
            } else {
                root.metaStatus = r.stderr.length ? r.stderr.trim() : Island.Cfg.t("META UPDATE FAILED")
                root.refreshMetaShortcut()
            }
        })
    }

    onVisibleChanged: if (visible) root.refreshMetaShortcut()
    Component.onCompleted: root.refreshMetaShortcut()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(12, Math.round(16 * root.uiScale))
        spacing: Math.max(8, Math.round(10 * root.uiScale))

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(34 * root.uiScale)
            Rectangle {
                Layout.preferredWidth: Math.round(72 * root.uiScale)
                Layout.preferredHeight: Math.round(30 * root.uiScale)
                radius: height / 2
                color: backMouse.containsMouse ? Island.Theme.surfaceHigh : "transparent"
                border.width: 1
                border.color: Island.Theme.outline
                Text {
                    anchors.centerIn: parent
                    text: Island.Cfg.t("‹ BACK")
                    font.family: Island.Theme.font
                    font.pointSize: Math.max(8, 8 * root.uiScale)
                    font.bold: true
                    color: Island.Theme.fg
                }
                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }
            Text {
                Layout.fillWidth: true
                text: Island.Cfg.t("LAUNCHER / SETTINGS")
                font.family: Island.Theme.font
                font.pointSize: Math.max(11, 12 * root.uiScale)
                font.bold: true
                color: Island.Theme.fg
            }
            DotGlyph {
                Layout.preferredWidth: Math.round(22 * root.uiScale)
                Layout.preferredHeight: Layout.preferredWidth
                name: "settings"
                color: Island.Theme.fg
                accentColor: Island.Theme.fg
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Island.Theme.outline }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(224 * root.uiScale)
            radius: Island.Theme.shapeLg
            color: Qt.rgba(Island.Theme.surfaceAlt.r, Island.Theme.surfaceAlt.g, Island.Theme.surfaceAlt.b, 0.34)
            border.width: 1
            border.color: Island.Theme.outline

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(13 * root.uiScale)
                spacing: Math.round(8 * root.uiScale)

                Text {
                    text: Island.Cfg.t("OPEN APP LAUNCHER")
                    font.family: Island.Theme.font
                    font.pointSize: Math.max(8, 8 * root.uiScale)
                    font.bold: true
                    color: Island.Theme.fgDim
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(10 * root.uiScale)

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: Island.Cfg.t("META / START KEY")
                            font.family: Island.Theme.font
                            font.pointSize: Math.max(7, 7.5 * root.uiScale)
                            font.bold: true
                            color: Island.Theme.fg
                        }
                        Text {
                            text: Island.Cfg.t("CAN BE ENABLED OR REMOVED")
                            font.family: Island.Theme.font
                            font.pointSize: Math.max(6, 6.5 * root.uiScale)
                            color: Island.Theme.fgFaint
                        }
                    }

                    Rectangle {
                        id: metaToggle
                        Layout.preferredWidth: Math.round(62 * root.uiScale)
                        Layout.preferredHeight: Math.round(28 * root.uiScale)
                        radius: height / 2
                        color: root.metaEnabled ? Qt.rgba(Island.Theme.fg.r, Island.Theme.fg.g, Island.Theme.fg.b, 0.18) : Island.Theme.surfaceHigh
                        border.width: 1
                        border.color: root.metaEnabled ? Island.Theme.fg : Island.Theme.outline
                        opacity: root.metaBusy ? 0.55 : 1.0

                        Text {
                            anchors.centerIn: parent
                            text: root.metaEnabled ? Island.Cfg.t("ON") : Island.Cfg.t("OFF")
                            font.family: Island.Theme.font
                            font.pointSize: Math.max(7, 7.5 * root.uiScale)
                            font.bold: true
                            color: root.metaEnabled ? Island.Theme.fg : Island.Theme.fgDim
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.metaBusy
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setMetaShortcut(!root.metaEnabled)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.metaStatus
                    font.family: Island.Theme.font
                    font.pointSize: Math.max(6, 6.5 * root.uiScale)
                    color: Island.Theme.fgFaint
                    elide: Text.ElideRight
                }

                Text {
                    text: Island.Cfg.t("OPTIONAL ALTERNATE SHORTCUT")
                    font.family: Island.Theme.font
                    font.pointSize: Math.max(6.5, 7 * root.uiScale)
                    font.bold: true
                    color: Island.Theme.fgDim
                }

                KQuickControls.KeySequenceItem {
                    id: launcherShortcut
                    Layout.fillWidth: true
                    keySequence: root.shortcutController ? root.shortcutController.globalShortcutSequence : ""
                    multiKeyShortcutsAllowed: false
                    showClearButton: true
                    showCancelButton: true
                    onKeySequenceModified: {
                        if (root.shortcutController) root.shortcutController.setGlobalShortcut(launcherShortcut.keySequence)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: Island.Cfg.t("CLEAR REMOVES THE ALTERNATE COMBINATION")
                    font.family: Island.Theme.font
                    font.pointSize: Math.max(6, 6.5 * root.uiScale)
                    color: Island.Theme.fgFaint
                    elide: Text.ElideRight
                }
            }
        }
        Text {
            text: Island.Cfg.t("DOCK WINDOWS")
            font.family: Island.Theme.font; font.pixelSize: 12 * root.uiScale
            color: Island.Theme.fgDim
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [{key: "dockCurrentDesktopOnly", label: "ONLY THIS DESKTOP"},
                        {key: "dockCurrentScreenOnly", label: "ONLY THIS SCREEN"}]
                QQC2.AbstractButton {
                    id: dockOption
                    required property var modelData
                    readonly property bool on: root.panelConfig?.[modelData.key] ?? false
                    objectName: "dockOption-" + modelData.key
                    width: optionText.implicitWidth + 24
                    height: 30 * root.uiScale
                    checkable: true
                    checked: on
                    Accessible.name: Island.Cfg.t(modelData.label)
                    onClicked: if (root.panelConfig) root.panelConfig[modelData.key] = !on
                    background: Rectangle {
                        radius: height / 2
                        color: dockOption.on ? Island.Theme.inverted : dockOption.hovered ? Island.Theme.surfaceHigh : Island.Theme.surfaceAlt
                    }
                    contentItem: Text {
                        id: optionText
                        text: Island.Cfg.t(dockOption.modelData.label)
                        color: dockOption.on ? Island.Theme.invertedFg : Island.Theme.fgDim
                        font.family: Island.Theme.font; font.pixelSize: 11 * root.uiScale
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        Text {
            text: Island.Cfg.t("APP VISIBILITY")
            font.family: Island.Theme.font; font.pixelSize: 12 * root.uiScale
            color: Island.Theme.fgDim
        }
        QQC2.TextField {
            id: appSearch
            objectName: "visibilitySearch"
            Layout.fillWidth: true
            Layout.preferredHeight: 34 * root.uiScale
            placeholderText: Island.Cfg.t("SEARCH APPS")
            color: Island.Theme.fg; placeholderTextColor: Island.Theme.fgDim
            font.family: Island.Theme.font; selectByMouse: true
            background: Rectangle { radius: Island.Theme.shapeMd; color: Island.Theme.surfaceAlt }
        }
        AppFilter { id: appList; inputModel: root.appsModel; query: appSearch.text }
        ListView {
            id: visibilityList
            objectName: "applicationVisibilityList"
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.minimumHeight: 80
            clip: true; spacing: 2
            model: appList
            QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
            delegate: QQC2.AbstractButton {
                id: entry
                required property var model
                readonly property string appId: appList.identity(model.favoriteId)
                readonly property bool shown: !root.hiddenApps.includes(appId)
                width: visibilityList.width; height: 38 * root.uiScale
                enabled: appId.length > 0
                Accessible.name: String(model.display) + " · " + Island.Cfg.t(shown ? "APP SHOWN" : "APP HIDDEN")
                Accessible.role: Accessible.CheckBox; Accessible.checked: shown
                onClicked: root.setAppVisible(appId, !shown)
                background: Rectangle { radius: Island.Theme.shapeMd; color: entry.hovered ? Island.Theme.surfaceHigh : "transparent" }
                contentItem: RowLayout {
                    spacing: 10
                    Kirigami.Icon { Layout.preferredWidth: 22; Layout.preferredHeight: 22; source: entry.model.decoration }
                    Text {
                        Layout.fillWidth: true
                        text: String(entry.model.display); textFormat: Text.PlainText
                        elide: Text.ElideRight; font.family: Island.Theme.font; font.pixelSize: 12 * root.uiScale
                        color: entry.shown ? Island.Theme.fg : Island.Theme.fgDim
                    }
                    Text {
                        text: entry.shown ? "visibility" : "visibility_off"
                        font.family: Island.Theme.fontIcons; font.pixelSize: 20
                        color: entry.shown ? Island.Theme.fg : Island.Theme.fgFaint
                    }
                }
            }
            Text {
                anchors.centerIn: parent; visible: visibilityList.count === 0
                text: Island.Cfg.t("NO APPS FOUND"); color: Island.Theme.fgDim
                font.family: Island.Theme.font; font.pixelSize: 12
            }
        }
    }
}
