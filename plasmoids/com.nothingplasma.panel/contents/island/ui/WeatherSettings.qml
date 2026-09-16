pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "WeatherData.js" as Data

ColumnLayout {
    id: root
    spacing: 12
    property var weather: Weather
    property var places: []
    property string searchError: ""
    signal closed()
    function searchCity() {
        if (cityInput.text.trim().length < 2) return;
        places = []; searchError = "";
        searchRequest.get(Data.searchUrl(cityInput.text, Cfg.turkish ? "tr" : "en"), data => {
            places = Data.locations(data);
            if (!places.length) searchError = Cfg.t("WEATHER NO CITY");
        }, () => searchError = Cfg.t("WEATHER ERROR"));
    }
    WeatherRequest { id: searchRequest }
    RowLayout {
        Layout.fillWidth: true
        Text { Layout.fillWidth: true; text: Cfg.t("WEATHER SETTINGS"); font.family: Theme.fontDots; font.pixelSize: 23; color: Theme.fg }
        QQC2.AbstractButton {
            Layout.preferredWidth: 28; Layout.preferredHeight: 28
            Accessible.name: Cfg.t("CLOSE")
            onClicked: root.closed()
            contentItem: Text { text: "close"; font.family: Theme.fontIcons; font.pixelSize: 20; color: Theme.fg; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
    }
    Text { Layout.fillWidth: true; text: root.weather.detail; wrapMode: Text.Wrap; font.family: Theme.font; font.pixelSize: 12; color: Theme.fgDim }
    RowLayout {
        Layout.fillWidth: true
        QQC2.TextField {
            id: cityInput
            objectName: "weatherCityInput"
            Layout.fillWidth: true; Layout.preferredHeight: 38
            text: Cfg.weatherCity
            placeholderText: Cfg.t("WEATHER CITY SEARCH")
            font.family: Theme.font; color: Theme.fg; placeholderTextColor: Theme.fgDim
            selectByMouse: true
            background: Rectangle { radius: Theme.shapeMd; color: Theme.surfaceAlt }
            onAccepted: root.searchCity()
            onTextEdited: { searchRequest.cancel(); root.places = []; root.searchError = ""; }
        }
        QQC2.AbstractButton {
            Layout.preferredWidth: 38; Layout.preferredHeight: 38
            enabled: cityInput.text.trim().length >= 2 && !searchRequest.busy
            Accessible.name: Cfg.t("SEARCH CITY")
            onClicked: root.searchCity()
            background: Rectangle { radius: Theme.shapeMd; color: Theme.surfaceHigh }
            contentItem: Text { text: "search"; font.family: Theme.fontIcons; font.pixelSize: 21; color: Theme.fg; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: searchRequest.busy ? Cfg.t("WEATHER LOADING") : root.searchError
        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 12; wrapMode: Text.Wrap
    }
    Repeater {
        model: root.places
        QQC2.AbstractButton {
            id: place
            required property var modelData
            Layout.fillWidth: true; Layout.preferredHeight: 40
            Accessible.name: modelData.label
            onClicked: { root.weather.selectLocation(modelData); root.places = []; }
            background: Rectangle { radius: Theme.shapeMd; color: place.hovered ? Theme.surfaceHigh : Theme.surfaceAlt }
            contentItem: Text { text: place.modelData.label; elide: Text.ElideRight; leftPadding: 10; rightPadding: 10; verticalAlignment: Text.AlignVCenter; color: Theme.fg; font.family: Theme.font; font.pixelSize: 12 }
        }
    }
    QQC2.AbstractButton {
        id: refresh
        Layout.fillWidth: true; Layout.preferredHeight: 36
        enabled: Cfg.weatherCity.trim().length > 0 && !root.weather.loading
        Accessible.name: Cfg.t("REFRESH WEATHER")
        onClicked: root.weather.fetch()
        background: Rectangle { radius: Theme.shapeMd; color: refresh.hovered ? Theme.surfaceHigh : Theme.surfaceAlt }
        contentItem: Text { text: Cfg.t("REFRESH WEATHER"); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; color: Theme.fg; font.family: Theme.font; font.pixelSize: 12 }
    }
    Text { text: "Open-Meteo · CC BY 4.0"; font.family: Theme.font; font.pixelSize: 10; color: Theme.fgFaint }
}
