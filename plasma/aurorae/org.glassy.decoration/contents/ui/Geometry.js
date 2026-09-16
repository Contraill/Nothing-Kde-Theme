.pragma library
// One circular radius; optional lower corners live in reserved decoration space.
// Insetting a stroke moves its radius as well as its bounding rectangle.
function path(c, width, height, radius, inset, roundBottom) {
    const s = inset || 0;
    const outer = Math.max(0, Math.min(radius, width / 2, height / 2));
    const r = Math.max(0, outer - s);
    const right = width - s, bottom = height - s;
    c.beginPath();
    c.moveTo(s, roundBottom ? bottom-r : bottom); c.lineTo(s, s + r);
    if (r > 0) c.arc(s + r, s + r, r, Math.PI, Math.PI * 1.5);
    else c.lineTo(s, s);
    c.lineTo(right - r, s);
    if (r > 0) c.arc(right - r, s + r, r, Math.PI * 1.5, Math.PI * 2);
    else c.lineTo(right, s);
    if (roundBottom && r > 0) {
        c.lineTo(right, bottom-r);
        c.arc(right-r, bottom-r, r, 0, Math.PI/2);
        c.lineTo(s+r, bottom);
        c.arc(s+r, bottom-r, r, Math.PI/2, Math.PI);
    } else c.lineTo(right, bottom);
    c.closePath();
}
