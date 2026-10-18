pragma Singleton

import QtQuick
import "Translations.js" as Translations
QtObject {
    id: cfg
    property string lang: "auto"
    // UI language can differ from the number/date formatting locale.
    readonly property string systemLanguage: Qt.uiLanguage || Qt.locale().uiLanguages[0] || Qt.locale().name

    // The island's language: its own choice, or KDE's when a catalog exists for it.
    readonly property string language: {
        if (cfg.lang !== "auto")
            return Translations.catalogs[cfg.lang] ? cfg.lang : "en";
        const code = cfg.systemLanguage.replace("-", "_");
        if (Translations.catalogs[code])
            return code;
        const base = code.split("_")[0];
        return Translations.catalogs[base] ? base : "en";
    }
    readonly property var languages: Translations.languages
    function languageName(code) {
        return Translations.catalogs[code]?.["LANGUAGE NAME"] ?? code;
    }
    readonly property string localeName: cfg.lang === "auto" ? Qt.locale().name : Qt.locale(cfg.language).name

    readonly property var locale: Qt.locale(cfg.localeName)
    // Follows KDE's region settings (LC_TIME): 12-hour formats contain AM/PM.
    readonly property bool clock24: !/a/i.test(Qt.locale().timeFormat(Locale.ShortFormat).replace(/'[^']*'/g, ""))

    readonly property string fmtHora: cfg.clock24 ? "HH:mm" : "h:mm AP"
    readonly property string fmtHoraCorta: cfg.clock24 ? "HH:mm" : "h:mm"
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
    property color colorFondo: "#000000"
    property color colorTarjeta: "#0B0B0B"
    property color colorInvertida: "#FFFFFF"
    property color colorAlerta: "#D71921"
    property color colorTexto: "#FFFFFF"
    property string fuenteUi: ""
    property string fuenteNumeros: ""

    // Keys are the msgctxt of po/panel; missing translations fall back to English.
    function t(key) {
        return Translations.catalogs[cfg.language][key] ?? Translations.catalogs.en[key] ?? key;
    }
}
