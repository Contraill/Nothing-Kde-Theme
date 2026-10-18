// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// How far `now` is through the span from `start` to `end` (local dates, so
// daylight saving changes cannot push it past 0..1).
function through(now, start, end) {
    return Math.max(0, Math.min(1, (now - start) / (end - start)));
}

// Day, week (from the locale's first weekday, 0 = Sunday), month and year.
function spans(now, firstWeekday) {
    const y = now.getFullYear(), m = now.getMonth(), d = now.getDate();
    const back = (now.getDay() - firstWeekday + 7) % 7;
    return {
        day: through(now, new Date(y, m, d), new Date(y, m, d + 1)),
        week: through(now, new Date(y, m, d - back), new Date(y, m, d - back + 7)),
        month: through(now, new Date(y, m, 1), new Date(y, m + 1, 1)),
        year: through(now, new Date(y, 0, 1), new Date(y + 1, 0, 1))
    };
}

function dayOfYear(now) {
    return Math.round((new Date(now.getFullYear(), now.getMonth(), now.getDate()) - new Date(now.getFullYear(), 0, 1)) / 86400000) + 1;
}

// Whole minutes left until the next midnight, rounded up.
function minutesToMidnight(now) {
    return Math.ceil((new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1) - now) / 60000);
}
