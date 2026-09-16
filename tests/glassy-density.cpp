// Isolated real-QStyle measurements; never installed with the theme.
#include <QtWidgets>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <cstdio>

static QJsonObject measure(QWidget &w, const QString &name)
{
    w.ensurePolished();
    const auto before = w.sizeHint();
    w.resize(800, 400);
    const auto after = w.sizeHint();
    return {{"name",name},{"height",before.height()},{"width",before.width()},
            {"fontHeight",w.fontMetrics().height()},{"resizeStable",before == after}};
}

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    const int fontSize = qEnvironmentVariableIntValue("GLASSY_TEST_FONT");
    if (fontSize) { auto font=app.font(); font.setPointSize(fontSize); app.setFont(font); }
    QPalette startup=app.palette();
    for (auto role : {QPalette::Window,QPalette::Button})
        startup.setColor(role,QColor(qEnvironmentVariable("GLASSY_TEST_WINDOW")));
    for (auto role : {QPalette::WindowText,QPalette::ButtonText,QPalette::Text})
        startup.setColor(role,QColor(qEnvironmentVariable("GLASSY_TEST_TEXT")));
    app.setPalette(startup);
    QWidget parent;
    QPushButton button("Apply / Uygula", &parent);
    QLineEdit input("Text", &parent), password("Password", &parent);
    password.setEchoMode(QLineEdit::Password);
    QComboBox combo(&parent), editable(&parent);
    combo.addItem("Selection"); editable.addItem("Selection"); editable.setEditable(true);
    QTabBar tabs(&parent); tabs.addTab("General"); tabs.addTab("Appearance"); tabs.setTabsClosable(true);
    QDialogButtonBox actions(QDialogButtonBox::Ok | QDialogButtonBox::Cancel, &parent);
    QJsonArray controls;
    for (auto pair : {qMakePair(static_cast<QWidget*>(&button),QString("button")),
                      qMakePair(static_cast<QWidget*>(&input),QString("input")),
                      qMakePair(static_cast<QWidget*>(&password),QString("password")),
                      qMakePair(static_cast<QWidget*>(&combo),QString("combo")),
                      qMakePair(static_cast<QWidget*>(&editable),QString("editableCombo")),
                      qMakePair(static_cast<QWidget*>(&tabs),QString("tabs")),
                      qMakePair(static_cast<QWidget*>(actions.button(QDialogButtonBox::Ok)),QString("dialogButton"))})
        controls.append(measure(*pair.first,pair.second));
    QMenu menu;
    auto *action=menu.addAction("Context menu text"); menu.addAction("Another action");
    menu.ensurePolished(); menu.adjustSize();
    controls.append(QJsonObject{{"name","menuItem"},{"height",menu.actionGeometry(action).height()},
        {"fontHeight",menu.fontMetrics().height()},{"resizeStable",true}});
    QJsonArray phases;
    const auto *style=app.style();
    // Exercise a real open QMenu with live Qt palette events, then a newly
    // created menu in the SAME process. No style reload/repolish/restart.
    const QPalette initial=app.palette();
    for (int phase=0; phase<3; ++phase) {
        QPalette palette=initial;
        if (phase==1) {
            palette.setColor(QPalette::Window,QColor("#16191f"));
            palette.setColor(QPalette::Base,QColor("#16191f"));
            palette.setColor(QPalette::Button,QColor("#16191f"));
            palette.setColor(QPalette::WindowText,QColor("#edefef"));
            palette.setColor(QPalette::Text,QColor("#edefef"));
            palette.setColor(QPalette::ButtonText,QColor("#edefef"));
        }
        app.setPalette(palette); // Test stimulus only; not a product workaround.
        menu.popup(QPoint(10,10)); app.processEvents();
        const QImage image=menu.grab().toImage();
        QMenu fresh; fresh.addAction("Context menu text"); fresh.addAction("Another action");
        fresh.popup(QPoint(300,10)); app.processEvents();
        const QImage newImage=fresh.grab().toImage();
        phases.append(QJsonObject{{"palette",app.palette().color(QPalette::Window).name()},
            {"menuPalette",menu.palette().color(QPalette::Window).name()},
            {"standard",style->standardPalette().color(QPalette::Window).name()},
            {"pixel",image.pixelColor(image.width()/2,image.height()-8).name(QColor::HexArgb)},
            {"freshPixel",newImage.pixelColor(newImage.width()/2,newImage.height()-8).name(QColor::HexArgb)},
            {"sameStyle",style==app.style()}});
        if (qEnvironmentVariableIsSet("GLASSY_TEST_CAPTURE"))
            image.save(qEnvironmentVariable("GLASSY_TEST_CAPTURE")+QString::number(phase)+".png");
        fresh.hide(); menu.hide();
    }
    const auto result=QJsonDocument(QJsonObject{{"controls",controls},{"phases",phases},
        {"style",app.style()->objectName()},{"dpr",parent.devicePixelRatioF()}}).toJson();
    std::fwrite(result.constData(),1,result.size(),stdout);
}
