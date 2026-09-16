// Test-only preload: capture a real Dolphin in an isolated offscreen session.
// Never installed or loaded into the user's running Dolphin process.
#include <QApplication>
#include <QTimer>
#include <QWidget>
#include <QPixmap>
#include <QFile>
#include <QToolBar>
#include <QTabBar>
#include <QAbstractButton>
#include <cstdio>

static void scheduleCapture()
{
    QTimer::singleShot(2500, [] {
        for (auto *window : QApplication::topLevelWidgets()) {
            if (QString(window->metaObject()->className()) != "DolphinMainWindow") continue;
            window->resize(qEnvironmentVariableIsSet("NOTHING_DOLPHIN_CHECK_TABS") ? 640 : 1080, 700);
            QTimer::singleShot(500, window, [window] {
                bool ok = window->grab().save(qEnvironmentVariable("NOTHING_DOLPHIN_CAPTURE"));
                auto *toolbar = window->findChild<QToolBar *>("mainToolBar");
                for (auto *bar : window->findChildren<QTabBar *>()) {
                    for (int i = 0; i < bar->count(); ++i) {
                        auto *button = bar->tabButton(i, QTabBar::RightSide);
                        if (button) std::printf("TAB_CLOSE tab=%d width=%d buttonX=%d buttonWidth=%d rightGap=%d\n",
                            i, bar->tabRect(i).width(), button->x(), button->width(), bar->tabRect(i).right() - button->geometry().right());
                        if (qEnvironmentVariableIsSet("NOTHING_DOLPHIN_CHECK_TABS"))
                            ok = ok && button && button->width() >= 32;
                        if (button && qEnvironmentVariableIsSet("NOTHING_DOLPHIN_CHECK_TABS")) {
                            const auto frame = bar->tabRect(i).adjusted(3, 5, -3, -5);
                            const int delta = button->geometry().center().y() - frame.center().y();
                            std::printf("TAB_CLOSE_VERTICAL tab=%d delta=%d\n", i, delta);
                            ok = ok && qAbs(delta) <= 1;
                        }
                    }
                    if (qEnvironmentVariableIsSet("NOTHING_DOLPHIN_CHECK_TABS") && bar->count() > 1) {
                        const int before = bar->count();
                        auto *close = qobject_cast<QAbstractButton *>(bar->tabButton(before - 1, QTabBar::RightSide));
                        if (close) close->click();
                        ok = ok && bar->count() == before - 1;
                        std::printf("TAB_CLOSE_CLICK %d\n", bar->count() == before - 1);
                    }
                }
                std::printf("DOLPHIN_CAPTURE %d toolbar=%dx%d stylesheet=%d\n", ok,
                            toolbar ? toolbar->width() : 0, toolbar ? toolbar->height() : 0,
                            !qApp->styleSheet().isEmpty());
                QApplication::exit(ok ? 0 : 3);
            });
            return;
        }
        QApplication::exit(4);
    });
}
Q_COREAPP_STARTUP_FUNCTION(scheduleCapture)
