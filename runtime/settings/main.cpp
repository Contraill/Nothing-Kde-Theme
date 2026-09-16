// Settings utility only: native KConfig/QUiLoader, not an application style engine.
#include <QApplication>
#include <QDialog>
#include <QDialogButtonBox>
#include <QFile>
#include <QMessageBox>
#include <QProcess>
#include <QPushButton>
#include <QStandardPaths>
#include <QUiLoader>
#include <QVBoxLayout>
#include <KConfigLoader>
#include <KConfigGroup>
#include <KSharedConfig>
#include <KConfigDialogManager>
#include <KLocalizedString>
#include <KLocalizedTranslator>

int main(int argc, char **argv) {
    QApplication app(argc,argv);
    app.setApplicationName("glassy-settings");
    KLocalizedString::setApplicationDomain("glassydecoration");
    KLocalizedTranslator translator;
    translator.setTranslationDomain("glassydecoration");
    translator.addContextToMonitor("GlassyConfig");
    app.installTranslator(&translator);
    const auto data=QStandardPaths::GenericDataLocation;
    const QString package=QStandardPaths::locate(data,"kwin/decorations/org.glassy.decoration",QStandardPaths::LocateDirectory);
    const QString helper=QStandardPaths::locate(data,"nothing-plasma/bin/appearance.py");
    if(package.isEmpty() || helper.isEmpty()) return 2;
    QDialog dialog; dialog.setWindowTitle("Glassy Settings"); dialog.resize(600,520);
    QVBoxLayout layout(&dialog);
    QFile ui(package+"/contents/ui/config.ui"); if(!ui.open(QIODevice::ReadOnly)) return 3;
    QUiLoader loader; QWidget *form=loader.load(&ui,&dialog); if(!form) return 4;
    layout.addWidget(form);
    QFile xml(package+"/contents/config/main.xml");
    auto config=KSharedConfig::openConfig("auroraerc");
    KConfigLoader skeleton(KConfigGroup(config,"org.glassy.decoration"),&xml);
    KConfigDialogManager manager(form,&skeleton); manager.updateWidgets();
    QDialogButtonBox buttons(QDialogButtonBox::Apply|QDialogButtonBox::Close);
    auto *reset=buttons.addButton(i18n("Reset to Glassy defaults"),QDialogButtonBox::ResetRole);
    layout.addWidget(&buttons);
    QObject::connect(reset,&QPushButton::clicked,&manager,&KConfigDialogManager::updateWidgetsDefault);
    QObject::connect(&buttons,&QDialogButtonBox::rejected,&dialog,&QDialog::reject);
    QProcess process;
    QObject::connect(buttons.button(QDialogButtonBox::Apply),&QPushButton::clicked,&dialog,[&] {
        manager.updateSettings(); skeleton.save();
        buttons.setEnabled(false);
        process.start("python3",{helper,"sync"});
    });
    QObject::connect(&process,&QProcess::finished,&dialog,[&](int code,QProcess::ExitStatus) {
        buttons.setEnabled(true);
        if(code) QMessageBox::warning(&dialog,"Glassy",QString::fromUtf8(process.readAllStandardError()));
    });
    QObject::connect(&process,&QProcess::errorOccurred,&dialog,[&](QProcess::ProcessError error) {
        if(error==QProcess::FailedToStart) {buttons.setEnabled(true); QMessageBox::warning(&dialog,"Glassy",process.errorString());}
    });
    dialog.show(); return app.exec();
}
