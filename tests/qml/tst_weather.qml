import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui/WeatherData.js" as Data
Item {
    width: 600; height: 450
    property var requests: []
    Island.WeatherRequest {
        id: transport
        createRequest: () => {
            const request = {readyState:0, status:0, responseText:"", onreadystatechange:null,
                open(method, url) { this.url = url; }, send() {}, abort() { this.aborted = true; }};
            requests.push(request); return request;
        }
    }
    Island.WeatherWidget { id: badge; width: 100; height: 40 }
    QtObject {
        id: savedCity
        property string islandWeatherCity: ""
        property string islandWeatherLatitude: ""
        property string islandWeatherLongitude: ""
        property string islandWeatherLocationQuery: ""
    }
    Component { id: settingsFactory; Island.WeatherSettings { width: 350 } }
    SignalSpy { id: configure; target: badge; signalName: "configureRequested" }
    TestCase {
        name: "Weather"
        when: windowShown
        property int successes: 0
        property int failures: 0
        function init() { Island.Backend.preview = true; requests = []; successes = 0; failures = 0; configure.clear(); }
        function cleanup() { transport.cancel(); transport.deadline.interval = 12000; }
        function request() { transport.get("https://example.test/weather", data => ++successes, () => ++failures); }
        function finish(xhr, status, text) { xhr.status=status; xhr.responseText=text; xhr.readyState=XMLHttpRequest.DONE; xhr.onreadystatechange(); }
        function test_stale_request_cannot_overwrite_new_city() {
            request(); const old = requests[0];
            request(); verify(old.aborted);
            finish(old, 200, "{}"); compare(successes, 0);
            finish(requests[1], 200, "{}"); compare(successes, 1); compare(transport.busy, false);
        }
        function test_errors_and_retry() {
            request(); finish(requests[0], 200, "<html>gateway</html>"); compare(failures, 1);
            request(); finish(requests[1], 503, "{}"); compare(failures, 2);
            request(); finish(requests[2], 200, "{}"); compare(successes, 1);
        }
        function test_timeout_cancels_and_ignores_late_response() {
            transport.deadline.interval = 15; request();
            tryCompare(this, "failures", 1);
            verify(requests[0].aborted); compare(transport.busy, false);
            finish(requests[0], 200, "{}"); compare(successes, 0);
        }
        function test_response_validation_and_city_search() {
            compare(Data.locations({}).length, 0);
            compare(Data.locations({results:[{name:"X",latitude:null,longitude:3}]}).length, 0);
            const place = Data.locations({results:[{name:"Istanbul",admin1:"Istanbul",country:"Türkiye",latitude:41,longitude:29}]})[0];
            compare(place.label, "Istanbul, Türkiye");
            verify(Data.searchUrl("İstanbul & test", "tr").includes(encodeURIComponent("İstanbul & test")));
            compare(Data.current({current:{temperature_2m:0,weather_code:0,is_day:0}}).temp, "0°");
            verify(!Data.validCoordinates("", ""));
            let rejected = false;
            try { Data.current({current:{temperature_2m:null,weather_code:0}}); } catch(e) { rejected = true; }
            verify(rejected);
            compare(Data.icon(0, false), "clear_night");
            compare(Data.description(95), "WEATHER STORM");
        }
        function test_city_selection_saves_coordinates() {
            Island.Weather.panelConfig = savedCity;
            const settings = settingsFactory.createObject(parent);
            settings.places = [{label:"İstanbul, Türkiye", latitude:41.01, longitude:28.98}];
            wait(20);
            let option = null;
            for (let child of settings.children) {
                if (child.Accessible && child.Accessible.name === "İstanbul, Türkiye") option = child;
            }
            verify(option !== null);
            mouseClick(option);
            compare(savedCity.islandWeatherCity, "İstanbul, Türkiye");
            compare(savedCity.islandWeatherLatitude, "41.01");
            compare(savedCity.islandWeatherLongitude, "28.98");
            compare(savedCity.islandWeatherLocationQuery, savedCity.islandWeatherCity);
            compare(settings.places.length, 0);
            settings.destroy();
            Island.Weather.panelConfig = null;
        }
        function test_badge_opens_configuration() { mouseClick(badge); compare(configure.count, 1); }
    }
}
