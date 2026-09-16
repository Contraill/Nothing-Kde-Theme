// SPDX-License-Identifier: GPL-3.0-or-later
// Qt resource inspection only: no GUI, Globals singleton or notification server.
#include <QGuiApplication>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLibrary>
#include <QLibraryInfo>
#include <QQmlEngine>
#include <QQmlComponent>
#include <cstdio>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QLibrary native(QLibraryInfo::path(QLibraryInfo::PluginsPath)
                    + "/plasma/applets/org.kde.plasma.notifications.so");
    if (!native.load()) return 1;
    QQmlEngine engine;
    QQmlComponent window(&engine);
    window.setData("import plasma.applet.org.kde.plasma.notifications\nNotificationWindow {}", QUrl());
    if (!window.isReady()) return 3;
    QJsonObject sources;
    sources.insert("NotificationWindow", "available");
    for (const auto *name : {"global/Globals.qml", "NotificationPopup.qml", "qmldir",
                            "components/ModelInterface.qml", "components/Body.qml",
                            "components/Icon.qml", "components/FooterLoader.qml"}) {
        QFile file(QStringLiteral(":/qt/qml/plasma/applet/org/kde/plasma/notifications/") + name);
        if (!file.open(QIODevice::ReadOnly)) return 2;
        sources.insert(QString::fromLatin1(name), QString::fromUtf8(file.readAll()));
    }
    const auto json = QJsonDocument(sources).toJson(QJsonDocument::Compact);
    std::fwrite(json.constData(), 1, json.size(), stdout);
    return 0;
}
