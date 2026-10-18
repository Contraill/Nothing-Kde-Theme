import QtQuick
import QtTest
import "../../widgets/packages/progress/contents/ui/progress.js" as Progress

TestCase {
    name: "ProgressWidget"

    function test_spans() {
        // Wednesday 1 July 2026, 18:00; weeks start on Monday (1).
        const s = Progress.spans(new Date(2026, 6, 1, 18, 0), 1);
        fuzzyCompare(s.day, 0.75, 1e-9);
        fuzzyCompare(s.week, (2 + 0.75) / 7, 0.01);
        fuzzyCompare(s.month, 0.75 / 31, 0.01);
        fuzzyCompare(s.year, (181 + 0.75) / 365, 0.001);
        // A Sunday-first week starts three days earlier.
        fuzzyCompare(Progress.spans(new Date(2026, 6, 1, 18, 0), 0).week, (3 + 0.75) / 7, 0.01);
        // Sunday is the last day of a Monday-first week.
        verify(Progress.spans(new Date(2026, 6, 5, 23, 0), 1).week > 0.99);
    }

    function test_day_and_midnight() {
        compare(Progress.dayOfYear(new Date(2026, 0, 1, 0, 1)), 1);
        compare(Progress.dayOfYear(new Date(2026, 11, 31, 23, 59)), 365);
        compare(Progress.dayOfYear(new Date(2028, 11, 31, 12, 0)), 366);
        compare(Progress.minutesToMidnight(new Date(2026, 6, 1, 22, 30, 30)), 90);
        compare(Progress.minutesToMidnight(new Date(2026, 6, 1, 0, 0, 0)), 1440);
    }
}
