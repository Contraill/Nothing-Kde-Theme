import QtQuick
import QtTest
import "../../widgets/packages/date/contents/ui/components" as Calendar

Item {
    width: 300; height: 300
    Calendar.NothingColors { id: colors; themeMode: 0; useSystemAccent: false }
    Calendar.DatePages { id: page; anchors.fill: parent; colors: colors; today: new Date(2024, 1, 29, 12) }
    TestCase {
        name: "DatePages"
        when: windowShown
        function init() {
            tryCompare(page, "turning", false)
            page.page = 0; page.monthDate = new Date(2024, 1, 1, 12); page.locale = Qt.locale("tr_TR")
        }
        function test_corner_click_animates_and_returns() {
            const button = findChild(page, "calendarFlip")
            mouseClick(button)
            verify(page.turning)
            verify(!button.enabled)
            page.togglePage() // no double-trigger halfway through a turn
            tryCompare(page, "turning", false)
            compare(page.page, 1)
            button.forceActiveFocus(); keyClick(Qt.Key_Space)
            tryCompare(page, "turning", false)
            compare(page.page, 0)
        }
        function test_month_navigation_and_year_rollover() {
            page.page = 1; page.monthDate = new Date(2024, 11, 1, 12)
            mouseClick(findChild(page, "calendarNext"))
            compare(page.monthDate.getFullYear(), 2025); compare(page.monthDate.getMonth(), 0)
            mouseClick(findChild(page, "calendarPrevious"))
            compare(page.monthDate.getFullYear(), 2024); compare(page.monthDate.getMonth(), 11)
        }
        function test_locale_week_start_and_leap_day() {
            compare(page.firstWeekday, 1)
            compare(page.dayAt(0).getDay(), 1)
            verify(page.sameDate(page.dayAt(page.offset + 28), page.today))
            page.locale = Qt.locale("en_US")
            compare(page.firstWeekday, 0); compare(page.dayAt(0).getDay(), 0)
            compare(page.t("Gün", "Date"), "Date")
            colors.themeMode = 1
            compare(page.colors.textPrimary, colors.systemIsDark ? colors.paletteBackground : colors.paletteText)
            colors.themeMode = 0
        }
    }
}
