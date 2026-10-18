pragma Singleton
import QtQuick
import "WeatherData.js" as Data

QtObject {
    id: root
    property var panelConfig: null
    property string temp: "—"
    property int code: -1
    property bool day: true
    property string city: ""
    property bool ready: false
    property bool failed: false
    property string errorKey: ""
    readonly property bool loading: transport.busy
    readonly property string desc: ready ? Cfg.t(Data.description(code)) : ""
    readonly property string icon: ready ? Data.icon(code, day) : "cloud"
    readonly property string detail: !Cfg.weatherCity.trim() ? Cfg.t("WEATHER CHOOSE CITY")
        : loading ? Cfg.t("WEATHER LOADING")
        : failed ? Cfg.t(errorKey) + (ready ? " · " + Cfg.t("WEATHER LAST VALUE") + " " + temp : "")
        : city + " · " + desc
    readonly property WeatherRequest transport: WeatherRequest {}

    function fail(key) { failed = true; errorKey = key; }
    function fetchCoordinates(latitude, longitude, label) {
        // Fahrenheit where the region uses US customary units (KDE region settings).
        transport.get(Data.forecastUrl(latitude, longitude, Qt.locale().measurementSystem === Locale.ImperialUSSystem), data => {
            try {
                const value = Data.current(data);
                temp = value.temp; code = value.code; day = value.day; city = label;
                ready = true; failed = false; errorKey = "";
            } catch (e) { fail("WEATHER ERROR"); }
        }, () => fail("WEATHER ERROR"));
    }
    function selectLocation(place) {
        if (!panelConfig || !Data.validCoordinates(place.latitude, place.longitude)) return;
        panelConfig.islandWeatherLatitude = String(place.latitude);
        panelConfig.islandWeatherLongitude = String(place.longitude);
        panelConfig.islandWeatherLocationQuery = place.label;
        panelConfig.islandWeatherCity = place.label;
        // Config propagation may be queued; explicit values avoid a second lookup.
        transport.cancel(); failed = false; ready = false; temp = "—";
        if (!Backend.preview) fetchCoordinates(place.latitude, place.longitude, place.label);
    }
    function fetch() {
        transport.cancel();
        if (Backend.preview || !Cfg.showWeather || !Cfg.weatherCity.trim()) return;
        failed = false; errorKey = "";
        const query = Cfg.weatherCity.trim();
        if (panelConfig?.islandWeatherLocationQuery === query
            && Data.validCoordinates(panelConfig.islandWeatherLatitude, panelConfig.islandWeatherLongitude)) {
            fetchCoordinates(panelConfig.islandWeatherLatitude, panelConfig.islandWeatherLongitude, query);
            return;
        }
        transport.get(Data.searchUrl(query, Cfg.turkish ? "tr" : "en"), data => {
            const found = Data.locations(data);
            if (!found.length) { fail("WEATHER NO CITY"); return; }
            const place = found[0];
            if (panelConfig) {
                panelConfig.islandWeatherLatitude = String(place.latitude);
                panelConfig.islandWeatherLongitude = String(place.longitude);
                panelConfig.islandWeatherLocationQuery = query;
            }
            fetchCoordinates(place.latitude, place.longitude, place.label);
        }, () => fail("WEATHER ERROR"));
    }
    readonly property Connections config: Connections {
        target: Cfg
        function onWeatherCityChanged() { root.ready = false; root.temp = "—"; root.failed = false; root.fetch(); }
        function onShowWeatherChanged() { root.fetch(); }
    }
    readonly property Timer tick: Timer {
        interval: root.failed ? 60000 : 900000
        running: !Backend.preview && Cfg.showWeather && Cfg.weatherCity.trim().length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetch()
    }
}
