// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.plasma.private.digitalclock as DigitalClock
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: page
    property int cfg_widgetVariant
    property alias cfg_use24HourFormat: hours24.checked
    property alias cfg_cityName: city.text
    property string cfg_timeZone
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent

    // Plasma's time zone list, searched by city or region.
    DigitalClock.TimeZoneModel { id: zones }
    readonly property var allZones: {
        const list = [];
        for (let row = 0; row < zones.rowCount(); ++row) {
            const index = zones.index(row, 0);
            list.push({id: String(zones.data(index, 257) ?? ""), region: String(zones.data(index, 258) ?? ""), city: String(zones.data(index, 259) ?? "")});
        }
        return list.filter(zone => zone.id && zone.id !== "UTC");
    }
    readonly property var matches: {
        const term = search.text.trim().toLocaleLowerCase();
        return term ? allZones.filter(zone => (zone.city + " " + zone.region + " " + zone.id).toLocaleLowerCase().includes(term)).slice(0, 40) : [];
    }

    ColumnLayout {
        spacing: 10
        RowLayout {
            QQC2.Label { text: i18n("Style:") }
            QQC2.ComboBox {
                model: [i18n("Hours over minutes"), i18n("World clock"), i18n("Pill")]
                currentIndex: Math.max(0, cfg_widgetVariant)
                onActivated: cfg_widgetVariant = currentIndex
            }
        }
        QQC2.CheckBox { id: hours24; text: i18n("24-hour clock") }
        QQC2.Label { text: i18n("World clock city: %1", page.cfg_timeZone) }
        QQC2.TextField { id: search; Layout.fillWidth: true; placeholderText: i18n("Search a city…") }
        Repeater {
            model: page.matches
            QQC2.ItemDelegate {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.city + " — " + modelData.region
                onClicked: { page.cfg_timeZone = modelData.id; city.text = modelData.city; search.text = ""; }
            }
        }
        RowLayout {
            QQC2.Label { text: i18n("Label:") }
            QQC2.TextField { id: city; Layout.fillWidth: true }
        }
        Glassy.ThemeSettings { id: theme }
    }
}
