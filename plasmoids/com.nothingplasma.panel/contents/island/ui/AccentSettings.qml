pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "."

ColumnLayout {
    id: root
    spacing: 16
    property var controls: Backend.controls
    property var panelConfig: Plasmoid.configuration
    readonly property bool busy: (controls?.accentBusy ?? false) || (controls?.themeBusy ?? false)
    readonly property color candidateColor: picker.selectedColor
    readonly property bool colorDragActive: picker.dragging
    readonly property color appliedColor: (controls?.accentReady ?? false) ? controls.activeAccent : Kirigami.Theme.focusColor
    property bool draftDirty: false
    property bool initialized: false
    signal closed()
    function resetDraft(): void { if (!initialized) return; picker.setColor(appliedColor); draftDirty = false; }
    function cancelDraft(): void { resetDraft(); root.closed(); }
    onAppliedColorChanged: if (!draftDirty) resetDraft()
    onVisibleChanged: if (visible) { resetDraft(); if (controls?.refreshAccent) controls.refreshAccent(); }
    function choose(value: color): void {
        if (!Backend.preview && controls && !busy) controls.applyAccent(value);
    }
    Component.onCompleted: {
        initialized = true
        resetDraft()
        if (controls?.refreshAccent) controls.refreshAccent()
        if (!Backend.preview && controls?.refreshAccentLinks) controls.refreshAccentLinks()
    }
    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: Cfg.t("ISLAND SETTINGS")
            font.family: Theme.fontDots; font.pixelSize: 24
            color: Theme.fg
        }
        QQC2.AbstractButton {
            id: closeButton
            Layout.preferredWidth: 28; Layout.preferredHeight: 28
            Accessible.name: Cfg.t("CLOSE")
            onClicked: root.cancelDraft()
            background: Rectangle { radius: 14; color: closeButton.hovered ? Theme.surfaceHigh : Theme.surfaceAlt }
            contentItem: Text {
                text: "close"; font.family: Theme.fontIcons; font.pixelSize: 17; color: Theme.fgDim
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: ["light", "dark"]
            QQC2.AbstractButton {
                id: modeButton
                required property string modelData
                readonly property bool selected: root.panelConfig?.appearanceMode === modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                enabled: !Backend.preview && !!root.controls && !root.busy
                checkable: true
                checked: selected
                Accessible.name: Cfg.t(modelData === "light" ? "LIGHT THEME" : "DARK THEME")
                onClicked: if (!selected) root.controls.applyTheme(modelData)
                background: Rectangle {
                    radius: Theme.shapeMd
                    color: modeButton.hovered ? Theme.surfaceHigh : Theme.surfaceAlt
                    border.width: modeButton.selected || modeButton.activeFocus ? 1 : 0
                    border.color: Theme.primary
                }
                contentItem: RowLayout {
                    spacing: 8
                    Item { Layout.fillWidth: true }
                    Text {
                        text: modeButton.modelData === "light" ? "light_mode" : "dark_mode"
                        font.family: Theme.fontIcons; font.pixelSize: 18
                        color: modeButton.selected ? Theme.primary : Theme.fgDim
                    }
                    Text {
                        text: Cfg.t(modeButton.modelData === "light" ? "LIGHT THEME" : "DARK THEME")
                        font.family: Theme.font; font.pixelSize: 12
                        color: modeButton.selected ? Theme.primary : Theme.fg
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
    QQC2.Switch {
        objectName: "showSystemTraySwitch"
        Layout.fillWidth: true
        text: Cfg.t("SHOW SYSTEM TRAY")
        checked: root.panelConfig?.showSystemTray ?? true
        onToggled: if (root.panelConfig) root.panelConfig.showSystemTray = checked
    }
    Text {
        Layout.fillWidth: true
        text: Cfg.t("SHOW IN COMPACT ISLAND")
        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 11
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: [
                {key: "showWorkspaces", label: "WORKSPACES"}, {key: "showWeather", label: "WEATHER SETTINGS"},
                {key: "showClock", label: "CLOCK"}, {key: "showMiniPlayer", label: "MINI PLAYER"},
                {key: "showNetwork", label: "PART NETWORK"}, {key: "showVolume", label: "PART SOUND"},
                {key: "showBattery", label: "BATTERY"}
            ]
            QQC2.AbstractButton {
                id: partButton
                required property var modelData
                readonly property bool shown: root.panelConfig?.[modelData.key] ?? true
                objectName: "compactPart-" + modelData.key
                width: partText.implicitWidth + 24
                height: 30
                checkable: true
                checked: shown
                Accessible.name: Cfg.t(modelData.label)
                onClicked: if (root.panelConfig) root.panelConfig[modelData.key] = !shown
                background: Rectangle {
                    radius: height / 2
                    color: partButton.shown ? Theme.inverted : partButton.hovered ? Theme.surfaceHigh : Theme.surfaceAlt
                    border.width: partButton.activeFocus ? 1 : 0
                    border.color: Theme.primary
                }
                contentItem: Text {
                    id: partText
                    text: Cfg.t(partButton.modelData.label)
                    color: partButton.shown ? Theme.invertedFg : Theme.fgDim
                    font.family: Theme.font; font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
    QQC2.AbstractButton {
        id: configureTrayButton
        objectName: "configureSystemTrayButton"
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        text: Cfg.t("CONFIGURE TRAY ITEMS")
        Accessible.name: text
        enabled: !!Backend.trayHost
        onClicked: { Backend.trayHost.configure(); root.closed(); }
        background: Rectangle {
            radius: Theme.shapeMd
            color: configureTrayButton.down || configureTrayButton.hovered ? Theme.surfaceHigh : Theme.surfaceAlt
            border.width: configureTrayButton.activeFocus ? 1 : 0
            border.color: Theme.primary
            opacity: configureTrayButton.enabled ? 1 : 0.3
        }
        contentItem: Text {
            text: configureTrayButton.text
            font.family: Theme.font; font.pixelSize: 12
            color: configureTrayButton.enabled ? Theme.fg : Theme.fgDim
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        }
    }
    QQC2.Switch {
        objectName: "islandAudioOsdSwitch"
        Layout.fillWidth: true
        text: Cfg.t("AUDIO OSD IN ISLAND")
        checked: root.panelConfig?.islandAudioOsd ?? true
        onToggled: if (root.panelConfig) root.panelConfig.islandAudioOsd = checked
    }
    QQC2.Switch {
        objectName: "confirmPowerActionsSwitch"
        Layout.fillWidth: true
        text: Cfg.t("CONFIRM POWER ACTIONS")
        checked: root.panelConfig?.confirmPowerActions ?? true
        onToggled: if (root.panelConfig) root.panelConfig.confirmPowerActions = checked
    }
    Text {
        Layout.fillWidth: true
        visible: (root.controls?.themeError ?? "").length > 0
        text: Cfg.t("THEME FAILED")
        wrapMode: Text.Wrap
        color: Theme.alert; font.family: Theme.font; font.pixelSize: 11
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 5
        Text { text: Cfg.t("ACCENT COLOR"); color: Theme.fg; font.family: Theme.font; font.pixelSize: 14 }
        Text {
            Layout.fillWidth: true
            text: Cfg.t("ACCENT DESCRIPTION"); wrapMode: Text.Wrap
            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 11
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Repeater {
            model: ["#D71921", "#DA7635", "#D3AE49", "#6BAF88", "#58A6C7", "#728ED5", "#AB82C5", "#808080"]
            QQC2.AbstractButton {
                id: swatch
                required property string modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                enabled: !root.busy
                Accessible.name: Cfg.t("ACCENT COLOR") + " " + modelData
                onClicked: { picker.setColor(modelData); root.choose(modelData); }
                background: Rectangle {
                    anchors.centerIn: parent
                    width: 32; height: 32; radius: 16
                    color: swatch.modelData
                    border.width: swatch.hovered || swatch.activeFocus || Qt.colorEqual(swatch.modelData, Kirigami.Theme.focusColor) ? 2 : 0
                    border.color: Theme.fg
                    opacity: swatch.enabled ? 1 : 0.5
                }
            }
        }
    }
    ColorPicker {
        id: picker
        objectName: "accentColorPicker"
        Layout.fillWidth: true
        enabled: !root.busy
        onEdited: root.draftDirty = true
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: Theme.shapeMd
            color: root.candidateColor
            border.width: 1; border.color: Theme.outline
            Accessible.role: Accessible.StaticText
            Accessible.name: Cfg.t("SELECTED COLOR")
        }
        QQC2.TextField {
            id: hexInput
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            enabled: !root.busy
            text: root.candidateColor.toString().toUpperCase()
            placeholderText: "#806EE7"
            Accessible.name: Cfg.t("HEX COLOR")
            font.family: Theme.font
            font.pixelSize: 13
            color: Theme.fg
            placeholderTextColor: Theme.fgDim
            selectionColor: Theme.primary
            selectedTextColor: Theme.brillo(Theme.primary) > 0.55 ? "#171717" : "#FFFFFF"
            leftPadding: 12; rightPadding: 12
            verticalAlignment: TextInput.AlignVCenter
            selectByMouse: true
            maximumLength: 7
            validator: RegularExpressionValidator { regularExpression: /#?[0-9a-fA-F]{6}/ }
            onTextEdited: {
                if (acceptableInput) { picker.setColor(text.startsWith("#") ? text : "#" + text); root.draftDirty = true; }
            }
            onAccepted: if (acceptableInput) root.choose(root.candidateColor)
            onEditingFinished: text = root.candidateColor.toString().toUpperCase()
            Connections {
                target: root
                function onCandidateColorChanged() {
                    if (!hexInput.activeFocus) hexInput.text = root.candidateColor.toString().toUpperCase();
                }
            }
            background: Rectangle {
                radius: Theme.shapeMd
                color: Theme.surfaceAlt
                border.width: 1
                border.color: hexInput.activeFocus ? Theme.primary : Theme.outline
            }
        }
        QQC2.AbstractButton {
            id: apply
            objectName: "accentApply"
            Layout.preferredWidth: 90; Layout.preferredHeight: 40
            enabled: !root.busy
            Accessible.name: Cfg.t("APPLY COLOR")
            onClicked: root.choose(root.candidateColor)
            background: Rectangle { radius: Theme.shapeMd; color: Theme.inverted; opacity: apply.enabled ? 1 : 0.3 }
            contentItem: Text {
                text: root.busy ? "…" : Cfg.t("APPLY COLOR")
                font.family: Theme.font; font.pixelSize: 12; color: Theme.invertedFg
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: (root.controls?.accentError ?? "").length > 0
        text: Cfg.t("ACCENT FAILED"); wrapMode: Text.Wrap
        color: Theme.alert; font.family: Theme.font; font.pixelSize: 11
    }
    Text {
        Layout.fillWidth: true
        text: Cfg.t("ACCENT LINKS")
        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 11
        wrapMode: Text.Wrap
    }
    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: ["starship", "spaceship", "fastfetch"]
            QQC2.AbstractButton {
                id: linkButton
                required property string modelData
                objectName: "accentLink-" + modelData
                readonly property bool linked: root.controls?.accentLinks?.enabled?.[modelData] ?? false
                visible: (root.controls?.accentLinks?.available?.[modelData] ?? false) || linked
                enabled: !Backend.preview && !(root.controls?.linksBusy ?? false)
                Layout.fillWidth: true; Layout.preferredHeight: 32
                Accessible.name: modelData + ": " + Cfg.t(linked ? "LINKED" : "UNLINKED")
                onClicked: root.controls.setAccentLink(modelData, !linked)
                background: Rectangle {
                    radius: Theme.shapeMd; color: Theme.surfaceAlt
                    border.width: linkButton.linked ? 1 : 0
                    border.color: Theme.primary
                }
                contentItem: Text {
                    text: linkButton.modelData + (linkButton.linked ? " ✓" : "")
                    color: linkButton.linked ? Theme.primary : Theme.fgDim
                    font.family: Theme.font; font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: (root.controls?.linksError ?? "").length > 0
        text: Cfg.t("LINK FAILED") + " " + (root.controls?.linksError ?? "")
        wrapMode: Text.Wrap; color: Theme.alert; font.family: Theme.font; font.pixelSize: 11
    }
}
