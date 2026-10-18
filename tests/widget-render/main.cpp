// SPDX-License-Identifier: GPL-3.0-or-later
// Test-only native applet host. No live Corona, panel layout or service writes.
#include <QApplication>
#include <QQuickWindow>
#include <QTimer>
#include <QImage>
#include <QDebug>
#include <QFont>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <cstdio>
#include <functional>
#include <KLocalizedString>
#include <KConfigGroup>
#include <KSharedConfig>
#include <Plasma/Corona>
#include <Plasma/Containment>
#include <Plasma/PluginLoader>
#include <plasmaquick/appletquickitem.h>

class TestCorona : public Plasma::Corona {
public:
    QRect screenGeometry(uint) const override { return QRect(0, 0, 400, 400); }
};

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    app.setApplicationName("nothing-kde-widget-check");
    if (argc < 3 || argc > 4) return 2;
    const bool clockProbe = argc == 4 && QString::fromLocal8Bit(argv[3]) == "--clock-probe";
    TestCorona corona;
    auto containment = corona.createContainment("org.kde.desktopcontainment");
    if (!containment) return 3;
    // libplasma 6.8 hands applets over as unique_ptr; the containment owns it once added.
    auto owned = Plasma::PluginLoader::self()->loadApplet(QString::fromLocal8Bit(argv[1]), clockProbe ? 4242 : 0);
    Plasma::Applet *applet = owned.get();
    if (!applet || !applet->pluginMetaData().isValid()) return 4;
    auto savedConfig = KSharedConfig::openConfig("nothing-clock-fixture");
    KConfigGroup savedApplet(savedConfig, "Applet");
    if (clockProbe) {
        if (qEnvironmentVariableIsSet("NOTHING_CLOCK_STYLE")) {
            auto config = savedApplet.group("Configuration").group("Appearance");
            config.writeEntry("fontStyle", qEnvironmentVariableIntValue("NOTHING_CLOCK_STYLE"));
            config.writeEntry("showDate", qEnvironmentVariableIntValue("NOTHING_CLOCK_DATE") != 0);
            config.writeEntry("themeMode", qEnvironmentVariableIntValue("NOTHING_CLOCK_MODE"));
            config.sync();
        }
        auto config = applet->config();
        savedApplet.group("Configuration").copyTo(&config);
        config.sync();
    }
    containment->addApplet(std::move(owned));
    auto item = PlasmaQuick::AppletQuickItem::itemForApplet(applet);
    if (!item) return 5;
    QQuickWindow window;
    window.setColor(QColor("#242424"));
    // NOTHING_RENDER_SIZE=WxH renders at the applet's own shape (pills, bars).
    QSize size(400, 400);
    const auto requested = qEnvironmentVariable("NOTHING_RENDER_SIZE").split(QLatin1Char('x'));
    if (requested.size() == 2) size = QSize(requested[0].toInt(), requested[1].toInt());
    window.resize(size);
    item->setParentItem(window.contentItem());
    item->setSize(QSizeF(size));
    item->setExpanded(true);
    window.show();
    if (argc == 4 && QString::fromLocal8Bit(argv[3]) == "--calendar") {
        window.resize(200, 200);
        item->setSize(QSizeF(200, 200));
        QTimer::singleShot(1500, &app, [&] {
            auto face = item->fullRepresentationItem();
            if (!face || !QMetaObject::invokeMethod(face, "togglePage")) app.exit(8);
        });
    }
    QJsonArray samples;
    const QList<QSize> sizes = {QSize(300, 200), QSize(400, 200), QSize(600, 300), QSize(400, 400), QSize(300, 200)};
    if (clockProbe) {
        // Exercise the date row being removed/reinserted before the resize sweep.
        const bool showDate = item->property("showDate").toBool();
        QTimer::singleShot(100, &app, [&, showDate] { item->setProperty("showDate", !showDate); });
        QTimer::singleShot(200, &app, [&, showDate] { item->setProperty("showDate", showDate); });
        for (int i = 0; i < sizes.size(); ++i) {
            QTimer::singleShot(500 + i * 350, &app, [&, i] {
                window.resize(sizes[i]);
                item->setSize(sizes[i]);
            });
            QTimer::singleShot(750 + i * 350, &app, [&, i] {
                QJsonArray labels;
                auto face = item->fullRepresentationItem();
                std::function<void(QQuickItem *)> visit = [&](QQuickItem *child) {
                    if (child->property("font").isValid() && child->property("text").isValid()) {
                        auto font = child->property("font").value<QFont>();
                        auto position = child->mapToItem(face, QPointF(0, 0));
                        labels.append(QJsonObject{{"text", child->property("text").toString()},
                            {"pixelSize", font.pixelSize()}, {"family", font.family()},
                            {"color", child->property("color").value<QColor>().name()},
                            {"x", position.x()}, {"y", position.y()},
                            {"width", child->width()}, {"height", child->height()},
                            {"visible", child->isVisible()}});
                    }
                    for (auto next : child->childItems()) visit(next);
                };
                if (face) visit(face);
                samples.append(QJsonObject{{"width", sizes[i].width()}, {"height", sizes[i].height()}, {"labels", labels}});
            });
        }
    }
    QTimer::singleShot(3000, &app, [&] {
        if (!item->fullRepresentationItem()) { qCritical() << "Missing full representation"; app.exit(6); return; }
        if (clockProbe) {
            applet->save(savedApplet);
            savedConfig->sync();
            QFile report(QString::fromLocal8Bit(argv[2]) + ".json");
            if (!report.open(QIODevice::WriteOnly)) { app.exit(9); return; }
            report.write(QJsonDocument(samples).toJson());
        }
        const bool saved = window.grabWindow().save(QString::fromLocal8Bit(argv[2]));
        std::printf("NOTHING_WIDGET_RENDERED %d\n", saved);
        app.exit(saved ? 0 : 7);
    });
    return app.exec();
}
