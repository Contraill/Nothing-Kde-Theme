import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island

TestCase {
    name: "Translations"
    function cleanup() { Island.Cfg.lang = "auto"; }
    function test_island_language_choice() {
        Island.Cfg.lang = "tr";
        compare(Island.Cfg.language, "tr");
        compare(Island.Cfg.t("COFFEE MODE"), "KAHVE MODU");
        Island.Cfg.lang = "en";
        compare(Island.Cfg.t("COFFEE MODE"), "COFFEE MODE");
        compare(Island.Cfg.t("N NOTIFICATIONS").replace("%1", 3), "3 NOTIFICATIONS");
    }
    function test_unknown_language_and_key_fall_back() {
        Island.Cfg.lang = "xx";
        compare(Island.Cfg.language, "en");
        compare(Island.Cfg.t("COFFEE MODE"), "COFFEE MODE");
        compare(Island.Cfg.t("NO SUCH KEY"), "NO SUCH KEY");
    }
    function test_languages_come_from_the_catalogs() {
        verify(Island.Cfg.languages.indexOf("tr") >= 0);
        compare(Island.Cfg.languageName("tr"), "Türkçe");
        compare(Island.Cfg.languageName("en"), "English");
    }
}
