// Exercise the same QUiLoader + KConfigLoader binding used by Aurorae's KCM.
#include <QApplication>
#include <QUiLoader>
#include <QFile>
#include <QSpinBox>
#include <QCheckBox>
#include <QComboBox>
#include <QTimer>
#include <QTemporaryDir>
#include <KConfigLoader>
#include <KConfigGroup>
#include <KSharedConfig>
#include <KConfigDialogManager>

int main(int argc, char **argv) {
    QApplication app(argc,argv);
    if(argc!=3) return 2;
    QString package=QString::fromLocal8Bit(argv[1]);
    QTemporaryDir temp;
    QFile ui(package+"/contents/ui/config.ui");
    if(!ui.open(QIODevice::ReadOnly)) return 3;
    QUiLoader loader; std::unique_ptr<QWidget> form(loader.load(&ui));
    if(!form) return 4;
    auto config=KSharedConfig::openConfig(temp.path()+"/auroraerc",KConfig::SimpleConfig);
    QFile xml(package+"/contents/config/main.xml");
    KConfigLoader skeleton(KConfigGroup(config,"org.glassy.decoration"),&xml);
    KConfigGroup(config,"unrelated").writeEntry("keep","user preference");
    KConfigDialogManager manager(form.get(),&skeleton);
    manager.updateWidgets();
    auto *radius=form->findChild<QSpinBox*>("kcfg_CornerRadius");
    auto *opacity=form->findChild<QSpinBox*>("kcfg_TitlebarOpacity");
    auto *blur=form->findChild<QCheckBox*>("kcfg_Blur");
    auto *bottom=form->findChild<QCheckBox*>("kcfg_RoundBottomCorners");
    if(!bottom || !bottom->isChecked()) return 10;
    bottom->setChecked(false);
    if(!radius||!opacity||!blur||radius->value()!=10||opacity->value()!=50||!blur->isChecked()) return 5;
    radius->setValue(24); opacity->setValue(100); blur->setChecked(false);
    manager.updateSettings(); skeleton.save(); config->reparseConfiguration();
    const auto group=KConfigGroup(config,"org.glassy.decoration");
    if(group.readEntry("RoundBottomCorners",true)) return 11;
    if(group.readEntry("CornerRadius",-1)!=24 || group.readEntry("TitlebarOpacity",-1)!=100 || group.readEntry("Blur",true))return 6;
    manager.updateWidgetsDefault();
    if(!bottom->isChecked()) return 12;
    // Exercise every new semantic preset via the actual KConfig UI binding.
    auto *windowOpacity=form->findChild<QSpinBox*>("kcfg_WindowOpacity");
    auto *popupOpacity=form->findChild<QSpinBox*>("kcfg_PopupOpacity");
    if(!windowOpacity || !popupOpacity || windowOpacity->value()!=50 || popupOpacity->value()!=75) return 7;
    for(auto *choice:form->findChildren<QComboBox*>()) choice->setCurrentIndex(choice->count()-1);
    windowOpacity->setValue(windowOpacity->minimum()); popupOpacity->setValue(100);
    manager.updateSettings(); skeleton.save(); config->reparseConfiguration();
    if(group.readEntry("WindowOpacity",0)!=10 || group.readEntry("PopupOpacity",0)!=100
       || group.readEntry("SurfaceRoundness",-1)!=2 || group.readEntry("InactiveButtons",-1)!=1) return 8;
    manager.updateWidgetsDefault(); manager.updateSettings(); skeleton.save(); config->reparseConfiguration();
    if(group.readEntry("WindowOpacity",50)!=50 || group.readEntry("SurfaceRoundness",1)!=1
       || KConfigGroup(config,"unrelated").readEntry("keep",QString())!="user preference") return 9;
    form->setWindowTitle("Glassy — native configuration"); form->show();
    QTimer::singleShot(1000,&app,[&]{form->grab().save(QString::fromLocal8Bit(argv[2]));app.quit();});
    return app.exec();
}
