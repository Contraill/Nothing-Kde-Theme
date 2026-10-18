// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton

import QtQuick
import "Translations.js" as Translations

// Island settings the panel binds from its configuration, the palette's base
// colours, and the language and time format the island speaks.
QtObject {
    id: cfg

    // "auto", or a catalog code from po/panel.
    property string lang: "auto"
    // The UI language can differ from the locale used for numbers and dates.
    readonly property string systemLanguage: Qt.uiLanguage || Qt.locale().uiLanguages[0] || Qt.locale().name
    // The chosen catalog, else KDE's language (or its base, "pt" for "pt_BR"), else English.
    readonly property string language: {
        if (lang !== "auto")
            return Translations.catalogs[lang] ? lang : "en";
        const code = systemLanguage.replace("-", "_");
        const base = code.split("_")[0];
        return Translations.catalogs[code] ? code : Translations.catalogs[base] ? base : "en";
    }
    readonly property var languages: Translations.languages
    function languageName(code) {
        return Translations.catalogs[code]?.["LANGUAGE NAME"] ?? code;
    }
    // Keys are the msgctxt of po/panel; a missing translation falls back to English.
    function t(key) {
        return Translations.catalogs[language][key] ?? Translations.catalogs.en[key] ?? key;
    }

    readonly property string localeName: lang === "auto" ? Qt.locale().name : Qt.locale(language).name
    readonly property var locale: Qt.locale(localeName)
    // KDE's region settings (LC_TIME) decide: a 12-hour format has AM/PM in it.
    readonly property bool clock24: !/a/i.test(Qt.locale().timeFormat(Locale.ShortFormat).replace(/'[^']*'/g, ""))
    readonly property string timeFormat: clock24 ? "HH:mm" : "h:mm AP"
    readonly property string shortTimeFormat: clock24 ? "HH:mm" : "h:mm"

    property bool ramUsage: false
    property bool showWorkspaces: true
    property bool showWeather: true
    property bool showClock: true
    property bool showNetwork: true
    property bool showVolume: true
    property bool showBattery: true
    property bool showMini: true
    property bool audioOsd: true
    property bool showPhone: true
    property string weatherCity: ""

    property color backgroundColor: "#000000"
    property color cardColor: "#0B0B0B"
    property color invertedColor: "#FFFFFF"
    property color alertColor: "#D71921"
    property color textColor: "#FFFFFF"
    // Empty: the bundled Space Grotesk and Nothing Dots.
    property string uiFont: ""
    property string dotFont: ""
}
