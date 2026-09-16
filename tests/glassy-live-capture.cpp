// Read-only observer inside opt-in test processes. Never installed with Glassy.
// No setPalette(), style replacement, repolish, or application restart.
#include <QtWidgets>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

static QJsonObject colors(const QPalette &p) {
    QJsonObject result;
    for (const auto role : {QPalette::Window,QPalette::WindowText,QPalette::Base,QPalette::Text,
                           QPalette::Button,QPalette::ButtonText,QPalette::Highlight,QPalette::HighlightedText})
        result[QString::number(role)]=p.color(role).name(QColor::HexArgb);
    return result;
}
static void observe() {
    const QString prefix=qEnvironmentVariable("GLASSY_LIVE_CAPTURE");
    if(prefix.isEmpty()) return;
    auto *timer=new QTimer(qApp);
    QObject::connect(timer,&QTimer::timeout,qApp,[prefix] {
        QFile phaseFile(prefix+".phase");
        if(!phaseFile.open(QIODevice::ReadOnly)) return;
        QString phase=QString::fromUtf8(phaseFile.readAll()).trimmed();
        if(phase.isEmpty()) return;
        for(auto *main:QApplication::topLevelWidgets()) {
            if(!main->isVisible() || !qobject_cast<QMainWindow*>(main)) continue;
            QJsonObject info{{"pid",QCoreApplication::applicationPid()},
                {"platform",QGuiApplication::platformName()},
                {"style",qApp->style()->objectName()},
                {"styleAddress",QString::number(reinterpret_cast<quintptr>(qApp->style()),16)},
                {"application",colors(qApp->palette())}, {"window",colors(main->palette())},
                {"standard",colors(qApp->style()->standardPalette())},
                {"wholeWindowOpacity",main->windowOpacity()}};
            main->grab().save(prefix+"-"+phase+".png");
            QJsonArray widgets;
            for(auto *w:main->findChildren<QWidget*>()) {
                if(!w->isVisible()) continue;
                if(!qobject_cast<QAbstractItemView*>(w) && !qobject_cast<QLineEdit*>(w)
                    && !qobject_cast<QToolButton*>(w) && !qobject_cast<QLabel*>(w)
                    && !w->inherits("KTextEditor::View")) continue;
                widgets.append(QJsonObject{{"class",w->metaObject()->className()},
                    {"name",w->objectName()},{"palette",colors(w->palette())}});
            }
            info["widgets"]=widgets;
            // Stateless render using the real style and live palette, not a mock.
            QImage probe(320,160,QImage::Format_ARGB32_Premultiplied);probe.fill(Qt::transparent);
            QPainter painter(&probe);
            QStyleOption win;win.initFrom(main);win.rect=QRect(0,0,100,100);
            qApp->style()->drawPrimitive(QStyle::PE_Widget,&win,&painter,main);
            QStyleOptionViewItem item;item.initFrom(main);item.rect=QRect(120,0,100,100);
            item.state|=QStyle::State_Selected|QStyle::State_Active;
            qApp->style()->drawPrimitive(QStyle::PE_PanelItemViewItem,&item,&painter,nullptr);
            painter.end();probe.save(prefix+"-"+phase+"-probe.png");
            info["surfacePixel"]=probe.pixelColor(40,40).name(QColor::HexArgb);
            info["selectionPixel"]=probe.pixelColor(160,40).name(QColor::HexArgb);
            QFile output(prefix+"-"+phase+".json");
            if(output.open(QIODevice::WriteOnly)) output.write(QJsonDocument(info).toJson());
            break;
        }
    });
    timer->start(1000);
}
Q_COREAPP_STARTUP_FUNCTION(observe)
