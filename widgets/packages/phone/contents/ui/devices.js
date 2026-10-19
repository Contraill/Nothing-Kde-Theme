// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// Device kinds: the key kept in the settings, the dot glyph of the rings and
// the picture of the circles (an SVG in contents/device-icons, else a theme icon).
var kinds = ["phone", "tablet", "laptop", "computer", "headphones", "earbuds", "watch", "mouse", "keyboard", "speaker", "controller"];
var glyphs = {phone: "phone", tablet: "phone", laptop: "laptop", computer: "computer", headphones: "headphones",
              earbuds: "earbuds", watch: "watch", mouse: "mouse", keyboard: "keyboard", speaker: "speaker", controller: "gamepad"};
var pictures = {laptop: "laptop", computer: "computer", headphones: "headphone", earbuds: "earbuds", watch: "watch",
                mouse: "mouse", keyboard: "keyboard", speaker: "speaker", controller: "controller"};

function glyph(kind) {
    return glyphs[kind] || "bolt";
}

// The circles' icon: a bundled SVG's base name, or a theme icon for phones.
function picture(kind) {
    return pictures[kind] || (kind === "tablet" ? "tablet" : "phone");
}

// A first guess from what the device says it is (its name, icon or type);
// the settings can change it.
function guess(text, fallback) {
    var t = String(text || "").toLowerCase();
    if (/earbud|buds|airpod/.test(t)) return "earbuds";
    if (/head(set|phone)|audio-head/.test(t)) return "headphones";
    if (/mouse/.test(t)) return "mouse";
    if (/keyboard/.test(t)) return "keyboard";
    if (/watch|wearable/.test(t)) return "watch";
    if (/speaker|audio-card|audio-speakers/.test(t)) return "speaker";
    if (/controller|gamepad|joypad|joystick|input-gaming/.test(t)) return "controller";
    if (/tablet/.test(t)) return "tablet";
    if (/laptop/.test(t)) return "laptop";
    if (/computer|desktop/.test(t)) return "computer";
    if (/phone|smartphone/.test(t)) return "phone";
    return fallback || "phone";
}
