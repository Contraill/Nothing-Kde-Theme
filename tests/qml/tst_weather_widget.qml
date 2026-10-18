import QtQuick
import QtTest
import "../../widgets/packages/weather/contents/ui/components" as Weather

TestCase {
    name: "WeatherWidgetService"
    Weather.WeatherService { id: service }
    function test_locations_with_and_without_coordinates() {
        const pinned = service.parseLocation("Famagusta|35.12489,33.94135");
        compare(pinned.label, "Famagusta");
        compare(pinned.latitude, 35.12489);
        compare(pinned.longitude, 33.94135);
        const named = service.parseLocation("famagusta");
        compare(named.label, "famagusta");
        verify(isNaN(named.latitude));
        verify(isNaN(service.parseLocation("Nowhere|123,456").latitude)); // out of range
    }
    function test_codes_pick_day_and_night_glyphs() {
        compare(service.glyph(0, false), "sun");
        compare(service.glyph(0, true), "moon");
        compare(service.glyph(2, true), "partly-cloudy-night");
        compare(service.glyph(3, false), "cloudy");
        compare(service.glyph(45, false), "fog");
        compare(service.glyph(63, false), "rain");
        compare(service.glyph(81, false), "rain");
        compare(service.glyph(75, false), "snow");
        compare(service.glyph(86, false), "snow");
        compare(service.glyph(96, false), "thunder");
    }
}
