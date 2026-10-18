import QtQuick
import QtTest
import "../../widgets/packages/date/contents/ui/components" as DateWidget

Item {
    width: 300; height: 300
    DateWidget.NothingColors { id: colors; themeMode: 0; useSystemAccent: false }
    DateWidget.DatePage { id: page; anchors.fill: parent; colors: colors; today: new Date(2024, 1, 29, 12); locale: Qt.locale("tr_TR") }
    TestCase {
        name: "DatePage"
        when: windowShown
        function init() { page.back = false; page.locale = Qt.locale("tr_TR"); }
        function test_click_turns_the_page_and_back() {
            mouseClick(page)
            verify(page.back)
            mouseClick(page)
            verify(!page.back)
        }
        function test_month_steps_roll_over_the_year() {
            page.back = true
            page.month = new Date(2024, 11, 1)
            wait(300) // the month fades in before its arrows take clicks
            mouseClick(findChild(page, "nextMonth"))
            compare(page.month.getFullYear(), 2025); compare(page.month.getMonth(), 0)
            verify(page.back) // the arrows do not turn the page
            mouseClick(findChild(page, "previousMonth"))
            compare(page.month.getFullYear(), 2024); compare(page.month.getMonth(), 11)
            page.back = false
            compare(page.month.getMonth(), 1) // turning back returns to the current month
        }
        function test_locale_week_start_and_leap_day() {
            const grid = findChild(page, "monthGrid")
            page.month = new Date(2024, 1, 1)
            compare(grid.dayAt(0).getDay(), 1) // Monday first in Turkish
            compare(grid.days, 29)
            compare(grid.dayAt(grid.offset + 28).getDate(), 29)
            page.locale = Qt.locale("en_US")
            compare(grid.dayAt(0).getDay(), 0) // Sunday first in US English
            colors.themeMode = 1
            compare(colors.textPrimary, colors.systemIsDark ? colors.paletteBackground : colors.paletteText)
            colors.themeMode = 0
        }
    }
}
