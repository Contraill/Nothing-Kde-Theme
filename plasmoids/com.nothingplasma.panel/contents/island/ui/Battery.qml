import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "."
Row {
    id: root
    spacing: 4
    property bool detailed: false

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: Backend.preview ? [] : ["Battery"]
    }

    readonly property var bat: Backend.preview ? ({"Has Battery": true, "State": "Charging", "Percent": 80}) : pmSource.data["Battery"] ?? ({})
    readonly property bool present: (bat["Has Battery"] ?? false) && bat["State"] !== "Unknown"
    readonly property int percent: bat["Percent"] ?? 0
    readonly property bool charging: (bat["State"] ?? "") === "Charging"

    visible: present
    Accessible.role: Accessible.StaticText
    Accessible.name: Cfg.t("BATTERY") + " · " + percent + "%" + (charging ? " · " + Cfg.t("CHARGING") : "")

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: {
            if (root.charging)
                return Icons.batCharging;
            const p = root.percent;
            if (p > 85)
                return Icons.batFull;
            if (p > 60)
                return Icons.bat3q;
            if (p > 35)
                return Icons.batHalf;
            if (p > 15)
                return Icons.batQuarter;
            return Icons.batEmpty;
        }
        color: root.charging ? Theme.primary : root.percent <= 15 ? Theme.error : Theme.fg
        font.family: Theme.fontIcons
        font.pixelSize: root.detailed ? 24 : 18
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.percent + "%"
        color: Theme.fgVariant
        font.family: root.detailed ? Theme.fontDots : Theme.font
        font.pixelSize: root.detailed ? 26 : Theme.labelMedium
    }
}
