// Plasma menus wrap QMenu and require QApplication, not QGuiApplication.
#include <QApplication>
#include <QLibrary>
#include <QLibraryInfo>
#include <QtQuickTest/quicktest.h>
int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    QLibrary notifications(QLibraryInfo::path(QLibraryInfo::PluginsPath) + "/plasma/applets/org.kde.plasma.notifications.so");
    if (qEnvironmentVariableIsSet("NOTHING_TEST_NOTIFICATIONS") && !notifications.load()) return 2;
    return quick_test_main(argc, argv, "nothing-native", QUICK_TEST_SOURCE_DIR);
}
