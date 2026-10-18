// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// Open-Meteo forecast for a place given as "City" or "Label|lat,lon".
QtObject {
    id: service
    property string location: ""
    property bool fahrenheit: false
    property string language: Qt.locale().name.split("_")[0]

    property string place: ""
    property bool loading: false
    property string error: ""
    property real temperature: NaN
    property real high: NaN
    property real low: NaN
    property int code: -1
    property bool night: false
    // Next hours: [{hour: Date, temperature, code, night}]
    property var hours: []
    property double fetchedAt: 0

    // "Label|lat,lon" skips the search.
    function parseLocation(text) {
        const value = String(text || "").trim();
        const pipe = value.indexOf("|");
        const label = pipe >= 0 ? value.slice(0, pipe).trim() : value;
        const match = (pipe >= 0 ? value.slice(pipe + 1) : value).match(/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/);
        if (match && Math.abs(Number(match[1])) <= 90 && Math.abs(Number(match[2])) <= 180)
            return {label: label, latitude: Number(match[1]), longitude: Number(match[2])};
        return {label: label, latitude: NaN, longitude: NaN};
    }
    // WMO weather interpretation codes, grouped the way the glyphs are.
    function glyph(code, night) {
        if (code === 0 || code === 1) return night ? "moon" : "sun";
        if (code === 2) return night ? "partly-cloudy-night" : "partly-cloudy-day";
        if (code === 3) return "cloudy";
        if (code === 45 || code === 48) return "fog";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "snow";
        if (code >= 95) return "thunder";
        if (code >= 51) return "rain";
        return "cloudy";
    }
    function condition(code) {
        if (code === 0) return i18n("Clear");
        if (code === 1) return i18n("Mostly clear");
        if (code === 2) return i18n("Partly cloudy");
        if (code === 3) return i18n("Cloudy");
        if (code === 45 || code === 48) return i18n("Fog");
        if (code >= 51 && code <= 57) return i18n("Drizzle");
        if (code >= 61 && code <= 67) return i18n("Rain");
        if (code >= 71 && code <= 77) return i18n("Snow");
        if (code >= 80 && code <= 82) return i18n("Showers");
        if (code === 85 || code === 86) return i18n("Snow showers");
        if (code >= 95) return i18n("Thunderstorm");
        return "";
    }

    function request(url, handle) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status !== 200) { service.loading = false; service.error = i18n("Weather is unavailable"); return; }
            try { handle(JSON.parse(xhr.responseText)); }
            catch (e) { service.loading = false; service.error = i18n("Weather is unavailable"); }
        };
        xhr.open("GET", url);
        xhr.send();
    }
    function refresh() {
        const parsed = parseLocation(location);
        if (!parsed.label && isNaN(parsed.latitude)) { error = i18n("Choose a city in the settings"); return; }
        loading = true;
        error = "";
        if (!isNaN(parsed.latitude)) { place = parsed.label; forecast(parsed.latitude, parsed.longitude); return; }
        request("https://geocoding-api.open-meteo.com/v1/search?count=1&language=" + language + "&name=" + encodeURIComponent(parsed.label), data => {
            const hit = data.results?.[0];
            if (!hit) { loading = false; error = i18n("City not found"); return; }
            place = hit.name;
            forecast(hit.latitude, hit.longitude);
        });
    }
    function forecast(latitude, longitude) {
        request("https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude
                + "&current=temperature_2m,weather_code,is_day&hourly=temperature_2m,weather_code,is_day"
                + "&daily=temperature_2m_max,temperature_2m_min&forecast_days=2&timezone=auto"
                + (fahrenheit ? "&temperature_unit=fahrenheit" : ""), data => {
            temperature = data.current.temperature_2m;
            code = data.current.weather_code;
            night = data.current.is_day === 0;
            high = data.daily.temperature_2m_max[0];
            low = data.daily.temperature_2m_min[0];
            // The API reports hours in the place's own zone, the same as "current".
            const now = data.current.time.slice(0, 13);
            const start = Math.max(0, data.hourly.time.findIndex(t => t.slice(0, 13) === now) + 1);
            hours = data.hourly.time.slice(start, start + 6).map((t, i) => ({
                hour: Number(t.slice(11, 13)),
                temperature: data.hourly.temperature_2m[start + i],
                code: data.hourly.weather_code[start + i],
                night: data.hourly.is_day[start + i] === 0
            }));
            fetchedAt = Date.now();
            loading = false;
        });
    }
    onLocationChanged: Qt.callLater(refresh)
    onFahrenheitChanged: Qt.callLater(refresh)
    // Offline or a failed request: try again in a minute, not in 15.
    onErrorChanged: if (error) retry.restart()
    property Timer retry: Timer { interval: 60 * 1000; onTriggered: service.refresh() }
    property Timer timer: Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: service.refresh()
    }
}
