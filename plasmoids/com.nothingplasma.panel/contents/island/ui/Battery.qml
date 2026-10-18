import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import "."
Item {
    id: root
    property bool detailed: false

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: Backend.preview ? [] : ["Battery"]
    }
    P5Support.DataSource {
        id: cellSource
        engine: "powermanagement"
        connectedSources: Backend.preview ? [] : (root.bat["Sources"] ?? [])
    }

    readonly property var bat: Backend.preview ? ({"Has Battery": true, "State": "Charging", "Percent": 80}) : pmSource.data["Battery"] ?? ({})
    readonly property bool present: (bat["Has Battery"] ?? false) && bat["State"] !== "Unknown"
    readonly property int percent: bat["Percent"] ?? 0
    readonly property string state: bat["State"] ?? ""
    readonly property bool charging: state === "Charging"
    readonly property real remainingMsec: bat["Smoothed Remaining msec"] || bat["Remaining msec"] || 0
    readonly property int chargeLimit: bat["Charge Stop Threshold"] ?? 100
    // Capacity of the first cell relative to its design capacity.
    readonly property int health: {
        const sources = bat["Sources"] ?? [];
        return sources.length ? (cellSource.data[sources[0]]?.["Capacity"] ?? -1) : -1;
    }

    function duration(msec): string {
        const minutes = Math.round(msec / 60000);
        const h = Math.floor(minutes / 60), m = minutes % 60;
        return h > 0 ? h + " " + Cfg.t("HOURS SHORT") + " " + m + " " + Cfg.t("MIN") : m + " " + Cfg.t("MIN");
    }
    readonly property string statusText: {
        if (state === "FullyCharged")
            return Cfg.t("FULLY CHARGED");
        if (state === "NoCharge")
            return chargeLimit < 100 && percent >= chargeLimit - 5
                ? Cfg.t("PLUGGED NOT CHARGING") + " · " + Cfg.t("CHARGE LIMIT") + " " + chargeLimit + "%"
                : Cfg.t("PLUGGED NOT CHARGING");
        if (charging)
            return remainingMsec > 0 ? Cfg.t("TIME TO FULL") + ": " + duration(remainingMsec) : Cfg.t("CHARGING");
        return remainingMsec > 0 ? Cfg.t("TIME LEFT") + ": " + duration(remainingMsec) : Cfg.t("CALCULATING");
    }

    visible: present
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    Accessible.role: Accessible.StaticText
    Accessible.name: Cfg.t("BATTERY") + " · " + percent + "%" + " · " + statusText

    Row {
        id: row
        spacing: 4

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

    // Hover shows remaining time, charge limit and battery health.
    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        anchors.margins: -4
        mainText: Cfg.t("BATTERY") + " · " + root.percent + "%"
        subText: root.health > 0 ? root.statusText + "\n" + Cfg.t("BATTERY HEALTH") + ": " + root.health + "%" : root.statusText
        location: PlasmaCore.Types.TopEdge
    }
}
