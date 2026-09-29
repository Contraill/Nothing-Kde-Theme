// Plasma menus wrap QMenu and require QApplication, not QGuiApplication.
#include <QApplication>
#include <QtQuickTest/quicktest.h>
int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    return quick_test_main(argc, argv, "nothing-native", QUICK_TEST_SOURCE_DIR);
}
