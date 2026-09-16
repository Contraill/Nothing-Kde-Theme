// Test-only Qt startup hook for fresh application processes. Never installed.
#include <QApplication>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QMenu>
#include <QMainWindow>
#include <QTimer>
#include <QStyle>
#include <QWindow>
#include <QDialog>
#include <QVBoxLayout>
#include <QLabel>
#include <QPushButton>

static void capture() {
    const auto path = qEnvironmentVariable("NOTHING_CAPTURE");
    if (path.isEmpty()) return;
    QTimer::singleShot(2000, qApp, [path] {
        QWidget *main = nullptr;
        for (auto *w : QApplication::topLevelWidgets())
            if (w->isVisible() && qobject_cast<QMainWindow *>(w)) { main = w; break; }
        if (!main) for (auto *w : QApplication::topLevelWidgets())
            if (w->isVisible() && !qobject_cast<QMenu *>(w)) { main = w; break; }
        if (!main) return;
        main->resize(950, 650); main->move(200, 130); main->raise(); main->activateWindow();
        main->setProperty("nothingAppearanceTest", true);
        QTimer::singleShot(1200, main, [path, main] {
            const auto image = main->grab().toImage().convertToFormat(QImage::Format_ARGB32);
            image.save(path + ".png");
            QJsonObject info{{"style", main->style()->objectName()},
                             {"class", main->metaObject()->className()},
                             {"windowOpacity", main->windowOpacity()},
                             {"translucent", main->testAttribute(Qt::WA_TranslucentBackground)},
                             {"windowColor", main->palette().color(QPalette::Window).name()},
                             {"textColor", main->palette().color(QPalette::WindowText).name()}};
            QJsonArray alphas;
            for (int y=20; y<image.height(); y+=80)
                for (int x=20; x<image.width(); x+=80) alphas.append(qAlpha(image.pixel(x,y)));
            info["sampleAlpha"] = alphas;
            QFile file(path + ".json");
            if (file.open(QIODevice::WriteOnly)) file.write(QJsonDocument(info).toJson());
            if (qEnvironmentVariableIsSet("NOTHING_CAPTURE_POPUPS")) {
                auto *menu = new QMenu(main);
                menu->addAction("Glass menu / Cam menü"); menu->addSeparator();
                menu->addAction("Opaque text and icons"); menu->addAction("Disabled action")->setEnabled(false);
                menu->popup(main->mapToGlobal(QPoint(170, 120)));
                QTimer::singleShot(800, menu, [menu, path, main] {
                    menu->grab().save(path + "-menu.png"); menu->close();
                    auto *dialog = new QDialog(main);
                    dialog->setWindowTitle("Glassy — dialog test");
                    auto *layout = new QVBoxLayout(dialog);
                    layout->addWidget(new QLabel("Palette text stays opaque; only the surface is translucent.", dialog));
                    auto *button = new QPushButton("Close / Kapat", dialog);
                    layout->addWidget(button);
                    QObject::connect(button, &QPushButton::clicked, dialog, &QDialog::close);
                    dialog->resize(520, 160); dialog->show();
                    QTimer::singleShot(800, dialog, [dialog, path] { dialog->grab().save(path + "-dialog.png"); dialog->close(); });
                });
            }
        });
    });
}
Q_COREAPP_STARTUP_FUNCTION(capture)
