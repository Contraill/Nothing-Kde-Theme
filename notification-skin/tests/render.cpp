// SPDX-License-Identifier: GPL-3.0-or-later
// Developer-only harness: load the installed KDE resource plugin, then render
// a QML fixture. It never initializes a notification server or changes Plasma.
#include <QApplication>
#include <QLibrary>
#include <QQmlApplicationEngine>
#include <QTimer>
#include <QQuickWindow>
#include <QImage>
#include <QDebug>
#include <QDir>
#include <QQuickItem>
#include <functional>
#include <cstdio>

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    if (argc < 4) return 2;
    QLibrary native(QString::fromLocal8Bit(argv[1]));
    if (!native.load()) { qCritical() << native.errorString(); return 1; }
    QQmlApplicationEngine engine;
    engine.load(QUrl::fromLocalFile(QString::fromLocal8Bit(argv[2])));
    if (engine.rootObjects().isEmpty()) return 1;
    if (argc > 4 && QString::fromLocal8Bit(argv[4]) == "--probe") {
        QTimer probe;
        int ticks = 0;
        probe.setInterval(100);
        QObject::connect(&probe, &QTimer::timeout, &app, [&] {
            auto root = engine.rootObjects().first();
            const bool passed = root->property("testPassed").toBool();
            if (passed || root->property("testFailed").toBool() || ++ticks > 250) {
                std::printf("QML integration probe: %s; UI language: %s\n", passed ? "PASS" : "FAIL",
                            qPrintable(root->property("detectedLanguage").toString()));
                app.exit(passed ? 0 : 1);
            }
        });
        probe.start();
        return app.exec();
    }
    if (argc > 4 && QString::fromLocal8Bit(argv[4]) == "--sequence") {
        const QString directory = QString::fromLocal8Bit(argv[3]);
        if (!QDir().mkpath(directory)) return 1;
        auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        if (!window) return 1;
        int frame = 0;
        bool sawPlaying = false;
        QTimer capture;
        capture.setInterval(50);
        QObject::connect(&capture, &QTimer::timeout, &app, [&] {
            int lightCount = 0;
            bool playing = false;
            std::function<void(QQuickItem *)> inspect = [&](QQuickItem *item) {
                if (item->objectName() == "nothingGlyphEdgeLights") {
                    ++lightCount;
                    playing |= item->property("playing").toBool();
                }
                for (auto child : item->childItems()) inspect(child);
            };
            inspect(window->contentItem());
            sawPlaying |= playing;
            const QString path = directory + QString("/frame-%1.png").arg(frame, 3, 10, QLatin1Char('0'));
            if (!window->grabWindow().save(path)) { app.exit(1); return; }
            if (++frame == 64) {
                std::printf("Edge lights: %d; started: %s; playing after 3.2s: %s\n", lightCount,
                            sawPlaying ? "yes" : "no", playing ? "yes" : "no");
                app.exit(lightCount > 0 && sawPlaying && !playing ? 0 : 1);
            }
        });
        capture.start();
        return app.exec();
    }
    QTimer::singleShot(800, &app, [&] {
        auto window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        app.exit(window && window->grabWindow().save(QString::fromLocal8Bit(argv[3])) ? 0 : 1);
    });
    return app.exec();
}
