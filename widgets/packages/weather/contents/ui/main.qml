import QtQuick
import "../../../../shared" as Glassy
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "components"
import "components/circle"
import "components/square"
import "components/wide"
import "everything"

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // --- Variant selection ---
    property int widgetVariant: Plasmoid.configuration.widgetVariant
    readonly property bool variantChosen: widgetVariant >= 0

    // --- Shared state ---
    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }

    // Configuration properties
    property string location: Plasmoid.configuration.location
    property int temperatureUnit: Plasmoid.configuration.temperatureUnit
    readonly property string displayLocation: location.indexOf("|") >= 0 ? location.split("|")[0].trim() : location

    // WEATHER DATA
    property string currentTemp: "--"
    property string highTemp: "--"
    property string lowTemp: "--"
    property string condition: i18n("Loading...")
    property int weatherCode: 0
    property string weatherIconPath: getWeatherIcon(0)

    // Daily forecast data (6 days from tomorrow) - only used by variant 0
    property var dailyForecastDays: []
    property var dailyForecastIcons: []
    property var dailyForecastHighs: []
    property var dailyForecastLows: []

    // Hourly forecast data - only used by variant 0
    property var hourlyForecastTimes: []
    property var hourlyForecastIcons: []
    property var hourlyForecastTemps: []

    // API state
    property double latitude: 0
    property double longitude: 0
    property bool isLoading: true
    property string errorMessage: ""

    // Temperature unit symbol
    readonly property string tempUnit: temperatureUnit === 0 ? "°C" : "°F"
    readonly property string apiTempUnit: temperatureUnit === 0 ? "celsius" : "fahrenheit"

    // Weather icon mapping function
    function getWeatherIcon(code) {
        var currentHour = new Date().getHours()
        var isNight = currentHour < 7 || currentHour >= 19

        if (code === 0) {
            return isNight ? Qt.resolvedUrl("../icons/partly_cloudy_night.svg") : Qt.resolvedUrl("../icons/sunny.svg")
        }
        else if (code === 1 || code === 2) {
            return isNight ? Qt.resolvedUrl("../icons/partly_cloudy_night.svg") : Qt.resolvedUrl("../icons/partly_cloudy_day.svg")
        }
        else if (code === 3) {
            return Qt.resolvedUrl("../icons/cloudy.svg")
        }
        else if (code === 45 || code === 48) {
            return Qt.resolvedUrl("../icons/rain_or_mist.svg")
        }
        else if (code === 51 || code === 53 || code === 55) {
            return Qt.resolvedUrl("../icons/rain_or_mist.svg")
        }
        else if (code === 56 || code === 57) {
            return Qt.resolvedUrl("../icons/rain_or_mist.svg")
        }
        else if (code === 61 || code === 63 || code === 65) {
            return Qt.resolvedUrl("../icons/rain_or_mist.svg")
        }
        else if (code === 66 || code === 67) {
            return Qt.resolvedUrl("../icons/rain_or_mist.svg")
        }
        else if (code === 71 || code === 73 || code === 75) {
            return Qt.resolvedUrl("../icons/snow_fall.svg")
        }
        else if (code === 77) {
            return Qt.resolvedUrl("../icons/snow_fall.svg")
        }
        else if (code === 80 || code === 81 || code === 82) {
            return Qt.resolvedUrl("../icons/rain_or_mist.svg")
        }
        else if (code === 85 || code === 86) {
            return Qt.resolvedUrl("../icons/snow_fall.svg")
        }
        else if (code === 95) {
            return Qt.resolvedUrl("../icons/thunder.svg")
        }
        else if (code === 96 || code === 99) {
            return Qt.resolvedUrl("../icons/thunder.svg")
        }

        return isNight ? Qt.resolvedUrl("../icons/partly_cloudy_night.svg") : Qt.resolvedUrl("../icons/sunny.svg")
    }

    // Weather condition text mapping
    function getWeatherCondition(code) {
        if (code === 0) return i18n("Clear")
        else if (code === 1) return i18n("Mainly Clear")
        else if (code === 2) return i18n("Partly Cloudy")
        else if (code === 3) return i18n("Overcast")
        else if (code === 45) return i18n("Fog")
        else if (code === 48) return i18n("Depositing Rime Fog")
        else if (code === 51) return i18n("Light Drizzle")
        else if (code === 53) return i18n("Drizzle")
        else if (code === 55) return i18n("Dense Drizzle")
        else if (code === 56) return i18n("Light Freezing Drizzle")
        else if (code === 57) return i18n("Freezing Drizzle")
        else if (code === 61) return i18n("Slight Rain")
        else if (code === 63) return i18n("Rain")
        else if (code === 65) return i18n("Heavy Rain")
        else if (code === 66) return i18n("Light Freezing Rain")
        else if (code === 67) return i18n("Freezing Rain")
        else if (code === 71) return i18n("Slight Snow")
        else if (code === 73) return i18n("Snow")
        else if (code === 75) return i18n("Heavy Snow")
        else if (code === 77) return i18n("Snow Grains")
        else if (code === 80) return i18n("Slight Rain Showers")
        else if (code === 81) return i18n("Rain Showers")
        else if (code === 82) return i18n("Violent Rain Showers")
        else if (code === 85) return i18n("Slight Snow Showers")
        else if (code === 86) return i18n("Heavy Snow Showers")
        else if (code === 95) return i18n("Thunderstorm")
        else if (code === 96) return i18n("Thunderstorm with Hail")
        else if (code === 99) return i18n("Heavy Thunderstorm with Hail")
        return i18n("Unknown")
    }

    // Get day name for forecast
    function getDayName(daysAhead) {
        var date = new Date()
        date.setDate(date.getDate() + daysAhead)
        var dayNames = [i18n("SUN"), i18n("MON"), i18n("TUE"), i18n("WED"), i18n("THU"), i18n("FRI"), i18n("SAT")]
        return dayNames[date.getDay()]
    }

    // Process daily forecast data (6 days from tomorrow)
    function processDailyForecast(dailyData) {
        var days = []
        var icons = []
        var highs = []
        var lows = []

        for (var i = 1; i <= 6; i++) {
            days.push(getDayName(i))
            icons.push(dailyData.weather_code[i])
            highs.push(Math.round(dailyData.temperature_2m_max[i]).toString())
            lows.push(Math.round(dailyData.temperature_2m_min[i]).toString())
        }

        dailyForecastDays = days
        dailyForecastIcons = icons
        dailyForecastHighs = highs
        dailyForecastLows = lows
    }

    // Process hourly forecast data
    function processHourlyForecast(hourlyData) {
        var times = []
        var icons = []
        var temps = []

        var currentDate = new Date()
        var currentHour = currentDate.getHours()

        var startHour = currentHour + 1
        var maxHour = currentHour + 12
        var targetEndHour = Math.min(startHour + 5, maxHour)

        for (var i = 0; i < hourlyData.time.length && times.length < 6; i++) {
            var timeStr = hourlyData.time[i]
            var hour = parseInt(timeStr.substring(11, 13))

            if (hour >= startHour && hour <= targetEndHour) {
                var displayHour = hour
                var ampm = " AM"
                if (hour >= 12) {
                    ampm = " PM"
                    if (hour > 12) displayHour = hour - 12
                }
                if (displayHour === 0) displayHour = 12

                times.push(displayHour + ampm)
                icons.push(hourlyData.weather_code[i])
                temps.push(Math.round(hourlyData.temperature_2m[i]).toString())
            }
        }

        hourlyForecastTimes = times
        hourlyForecastIcons = icons
        hourlyForecastTemps = temps
    }

    // Check if a hint matches any of the result's geographic fields
    function hintMatches(hint, fields, words, fullFields) {
        // Exact word/field match first (handles "Canada", "US", etc.)
        if (words.indexOf(hint) !== -1 || fullFields.indexOf(hint) !== -1)
            return true
        // Initialism match: "BC" matches "British Columbia" by checking
        // if each character matches the start of consecutive words
        if (hint.length >= 2 && hint.length <= 5) {
            for (var i = 0; i < fullFields.length; i++) {
                var fieldWords = fullFields[i].split(/\s+/)
                if (fieldWords.length === hint.length) {
                    var initialsMatch = true
                    for (var c = 0; c < hint.length; c++) {
                        if (!fieldWords[c] || fieldWords[c].charAt(0) !== hint.charAt(c)) {
                            initialsMatch = false
                            break
                        }
                    }
                    if (initialsMatch)
                        return true
                }
            }
        }
        return false
    }

    // Find the best matching result for hints like "BC", "Canada", etc.
    function pickBestResult(results, hints) {
        if (hints.length === 0 || results.length === 1)
            return results[0]

        for (var i = 0; i < results.length; i++) {
            var r = results[i]
            var fields = [r.country || "", r.country_code || "",
                          r.admin1 || "", r.admin2 || "", r.admin3 || ""]
            var words = fields.join(" ").toLowerCase().split(/\s+/)
            var fullFields = fields.map(function(f) { return f.toLowerCase() })

            var allMatch = true
            for (var j = 0; j < hints.length; j++) {
                if (!hintMatches(hints[j].toLowerCase(), fields, words, fullFields)) {
                    allMatch = false
                    break
                }
            }
            if (allMatch)
                return r
        }
        return results[0]
    }

    function parseConfiguredCoordinates() {
        var value = location
        if (value.indexOf("|") >= 0)
            value = value.split("|").slice(1).join("|")

        var match = value.match(/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/)
        if (!match)
            return null

        var lat = Number(match[1])
        var lon = Number(match[2])
        if (isNaN(lat) || isNaN(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180)
            return null

        return {
            latitude: lat,
            longitude: lon
        }
    }

    // Geocoding function
    function geocodeLocation() {
        isLoading = true
        errorMessage = ""

        var configuredCoordinates = parseConfiguredCoordinates()
        if (configuredCoordinates) {
            latitude = configuredCoordinates.latitude
            longitude = configuredCoordinates.longitude
            fetchWeatherData()
            return
        }

        var parts = location.split(",").map(function(s) { return s.trim() })
        var city = parts[0]
        var hints = parts.slice(1).filter(function(s) { return s.length > 0 })

        var xhr = new XMLHttpRequest()
        var url = "https://geocoding-api.open-meteo.com/v1/search?name=" +
                  encodeURIComponent(city) + "&count=10&language=en&format=json"

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.results && response.results.length > 0) {
                            var best = pickBestResult(response.results, hints)
                            latitude = best.latitude
                            longitude = best.longitude
                            fetchWeatherData()
                        } else {
                            errorMessage = i18n("Location not found")
                            isLoading = false
                            currentTemp = "--"
                            condition = i18n("Location not found")
                        }
                    } catch (e) {
                        errorMessage = "Error parsing location data"
                        isLoading = false
                        console.error("Geocoding parse error:", e)
                    }
                } else {
                    errorMessage = "Network error"
                    isLoading = false
                    console.error("Geocoding request failed:", xhr.status)
                }
            }
        }

        xhr.open("GET", url)
        xhr.send()
    }

    // Fetch weather data from Open-Meteo API
    function fetchWeatherData() {
        if (latitude === 0 && longitude === 0) {
            geocodeLocation()
            return
        }

        var xhr = new XMLHttpRequest()

        // Variant 0 needs full forecast data; variants 1 & 2 only need current + daily
        var needsFullForecast = (widgetVariant === 0)

        var url = "https://api.open-meteo.com/v1/forecast?" +
                  "latitude=" + latitude +
                  "&longitude=" + longitude +
                  "&current=temperature_2m,weather_code" +
                  (needsFullForecast ? "&hourly=temperature_2m,weather_code" : "") +
                  "&daily=temperature_2m_max,temperature_2m_min,weather_code" +
                  "&temperature_unit=" + apiTempUnit +
                  "&timezone=auto" +
                  "&forecast_days=" + (needsFullForecast ? "7" : "1")

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)

                        if (response.current) {
                            currentTemp = Math.round(response.current.temperature_2m).toString()
                            weatherCode = response.current.weather_code || 0
                            weatherIconPath = getWeatherIcon(weatherCode)
                            condition = getWeatherCondition(weatherCode)
                        }

                        if (response.daily) {
                            highTemp = Math.round(response.daily.temperature_2m_max[0]).toString()
                            lowTemp = Math.round(response.daily.temperature_2m_min[0]).toString()

                            if (needsFullForecast) {
                                processDailyForecast(response.daily)
                            }
                        }

                        if (needsFullForecast && response.hourly) {
                            processHourlyForecast(response.hourly)
                        }

                        isLoading = false
                        errorMessage = ""
                    } catch (e) {
                        errorMessage = "Error parsing weather data"
                        isLoading = false
                        console.error("Weather parse error:", e)
                    }
                } else {
                    errorMessage = "Failed to fetch weather"
                    isLoading = false
                    console.error("Weather request failed:", xhr.status)
                }
            }
        }

        xhr.open("GET", url)
        xhr.send()
    }

    // Timer to refresh weather data every 30 minutes
    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: fetchWeatherData()
    }

    onLocationChanged: geocodeLocation()

    onTemperatureUnitChanged: {
        if (latitude !== 0 || longitude !== 0) {
            fetchWeatherData()
        }
    }

    // Re-fetch when variant changes (may need different data)
    onWidgetVariantChanged: {
        if (latitude !== 0 || longitude !== 0) {
            fetchWeatherData()
        }
    }

    Component.onCompleted: geocodeLocation()

    // --- Compact representation ---


    // --- Full representation ---
    fullRepresentation: Loader {
        id: fullLoader

        Layout.preferredWidth: 200
        Layout.preferredHeight: 200
        Layout.minimumWidth: 200
        Layout.minimumHeight: 200

        sourceComponent: {
            if (!root.variantChosen) return selectorComponent

            // On desktop: variant-specific
            if (root.widgetVariant === 0) return weatherFullComponent
            if (root.widgetVariant === 1) return circularSingleComponent
            if (root.widgetVariant === 2) return circularMultiComponent
            if (root.widgetVariant === 3) return everyComponent

            return selectorComponent
        }
    }

    // 3: EveryThing-UI's square.
    Glassy.DotFont { id: everyFont }
    Component {
        id: everyComponent
        EveryWeather {
            colors: nColors
            family: everyFont.name
            temperature: root.currentTemp
            condition: root.condition
            code: root.weatherCode
        }
    }

    Component {
        id: selectorComponent
        VariantSelector {
            colors: nColors
        }
    }

    Component {
        id: weatherFullComponent
        Item {
            readonly property bool isWideLayout: width >= height * 2

            // SQUARE/VERTICAL LAYOUT
            Glassy.GlassySurface {
                anchors.fill: parent
                anchors.margins: 10
                backgroundColor: nColors.background
                foregroundColor: nColors.textPrimary
                visible: !parent.isWideLayout

                QQC2.SwipeView {
                    id: swipeView
                    anchors.fill: parent
                    anchors.margins: 15
                    currentIndex: 0
                    clip: true
                    orientation: Qt.Vertical

                    SquarePageOne {
                        colors: nColors
                        currentTemp: root.currentTemp
                        weatherIconPath: root.weatherIconPath
                        isLoading: root.isLoading
                        errorMessage: root.errorMessage
                        location: root.displayLocation
                    }

                    SquarePageTwo {
                        colors: nColors
                        highTemp: root.highTemp
                        lowTemp: root.lowTemp
                        condition: root.condition
                        isLoading: root.isLoading
                    }
                }
            }

            // WIDE LAYOUT
            Glassy.GlassySurface {
                anchors.fill: parent
                anchors.margins: 10
                backgroundColor: nColors.background
                foregroundColor: nColors.textPrimary
                visible: parent.isWideLayout

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 5

                    WidePageHeader {
                        colors: nColors
                        weatherIconPath: root.weatherIconPath
                        isLoading: root.isLoading
                        errorMessage: root.errorMessage
                        currentTemp: root.currentTemp
                        highTemp: root.highTemp
                        lowTemp: root.lowTemp
                        location: root.displayLocation
                        condition: root.condition
                    }

                    QQC2.SwipeView {
                        id: wideSwipeView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: 0
                        clip: true
                        orientation: Qt.Vertical

                        Item {
                            WideDailyForecast {
                                anchors.fill: parent
                                colors: nColors
                                dailyForecastDays: root.dailyForecastDays
                                dailyForecastIcons: root.dailyForecastIcons
                                dailyForecastHighs: root.dailyForecastHighs
                                dailyForecastLows: root.dailyForecastLows
                                getWeatherIcon: root.getWeatherIcon
                            }
                        }

                        Item {
                            WideHourlyForecast {
                                anchors.fill: parent
                                colors: nColors
                                hourlyForecastTimes: root.hourlyForecastTimes
                                hourlyForecastIcons: root.hourlyForecastIcons
                                hourlyForecastTemps: root.hourlyForecastTemps
                                getWeatherIcon: root.getWeatherIcon
                            }
                        }
                    }
                }
            }

            // Page Indicator
            Column {
                id: pageIndicator
                anchors {
                    right: parent.right
                    rightMargin: 16
                    verticalCenter: parent.verticalCenter
                }
                spacing: 8
                z: 100

                readonly property bool useWideLayout: parent.isWideLayout

                Repeater {
                    model: 2

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: {
                            var currentIdx = pageIndicator.useWideLayout ? wideSwipeView.currentIndex : swipeView.currentIndex
                            return currentIdx === index ? nColors.indicatorActive : nColors.indicatorInactive
                        }
                        opacity: {
                            var currentIdx = pageIndicator.useWideLayout ? wideSwipeView.currentIndex : swipeView.currentIndex
                            return currentIdx === index ? 0.95 : 0.45
                        }

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (pageIndicator.useWideLayout) {
                                    wideSwipeView.currentIndex = index
                                } else {
                                    swipeView.currentIndex = index
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                z: 5
                onWheel: {
                    if (parent.isWideLayout) {
                        if (wheel.angleDelta.y < 0) wideSwipeView.incrementCurrentIndex()
                        else if (wheel.angleDelta.y > 0) wideSwipeView.decrementCurrentIndex()
                    } else {
                        if (wheel.angleDelta.y < 0) swipeView.incrementCurrentIndex()
                        else if (wheel.angleDelta.y > 0) swipeView.decrementCurrentIndex()
                    }
                }
            }
        }
    }

    Component {
        id: circularSingleComponent
        SinglePageLayout {
            weatherIconPath: root.weatherIconPath
            condition: root.condition
            currentTemp: root.currentTemp
            highTemp: root.highTemp
            lowTemp: root.lowTemp
            isLoading: root.isLoading
            colors: nColors
        }
    }

    Component {
        id: circularMultiComponent
        Item {
            Glassy.GlassySurface {
                anchors.fill: parent
                anchors.margins: 10
                backgroundColor: nColors.background
                foregroundColor: nColors.textPrimary
                cornerRadius: width / 2

                QQC2.SwipeView {
                    id: circleSwipeView
                    anchors.fill: parent
                    anchors.margins: 15
                    currentIndex: 0
                    clip: true
                    orientation: Qt.Vertical

                    CirclePageOne {
                        weatherIconPath: root.weatherIconPath
                        isLoading: root.isLoading
                        errorMessage: root.errorMessage
                        colors: nColors
                    }

                    CirclePageTwo {
                        currentTemp: root.currentTemp
                        isLoading: root.isLoading
                        colors: nColors
                    }

                    CirclePageThree {
                        highTemp: root.highTemp
                        lowTemp: root.lowTemp
                        isLoading: root.isLoading
                        colors: nColors
                    }
                }
            }

            // Page Indicator
            Column {
                anchors {
                    right: parent.right
                    rightMargin: 16
                    verticalCenter: parent.verticalCenter
                }
                spacing: 8
                z: 100

                Repeater {
                    model: 3

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: circleSwipeView.currentIndex === index ? nColors.indicatorActive : nColors.indicatorInactive
                        opacity: circleSwipeView.currentIndex === index ? 0.95 : 0.45

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: circleSwipeView.currentIndex = index
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                z: 5
                onWheel: {
                    if (wheel.angleDelta.y < 0) circleSwipeView.incrementCurrentIndex()
                    else if (wheel.angleDelta.y > 0) circleSwipeView.decrementCurrentIndex()
                }
            }
        }
    }
}
