// Native KConfig round-trip; no session configuration is touched.
#include <QCoreApplication>
#include <QFile>
#include <QTemporaryDir>
#include <KConfigLoader>
#include <KConfigGroup>
#include <KSharedConfig>
int main(int argc,char **argv) {
    QCoreApplication app(argc,argv);
    if(argc!=2)return 2;
    QTemporaryDir temp;
    auto config=KSharedConfig::openConfig(temp.path()+"/panelrc",KConfig::SimpleConfig);
    {
        QFile xml(QString::fromLocal8Bit(argv[1]));
        KConfigLoader loader(config,&xml);
        auto *confirm=loader.findItem("General","confirmPowerActions");
        auto *mode=loader.findItem("General","appearanceMode");
        if(!confirm || !mode || !confirm->property().toBool()) return 3;
        confirm->setProperty(false);mode->setProperty(QStringLiteral("light"));
        loader.findItem("General","hiddenApplications")->setProperty(QStringList{"org.kde.kate.desktop", "kitty.desktop"});
        loader.findItem("General","islandWeatherCity")->setProperty(QStringLiteral("İstanbul, Türkiye"));
        loader.findItem("General","islandWeatherLocationQuery")->setProperty(QStringLiteral("İstanbul, Türkiye"));
        loader.findItem("General","islandWeatherLatitude")->setProperty(QStringLiteral("41.01"));
        loader.findItem("General","islandWeatherLongitude")->setProperty(QStringLiteral("28.98"));
        loader.save();
    }
    config->reparseConfiguration();
    {
        QFile xml(QString::fromLocal8Bit(argv[1]));
        KConfigLoader loader(config,&xml);
        if(loader.findItem("General","confirmPowerActions")->property().toBool()
           || loader.findItem("General","appearanceMode")->property().toString()!="light")return 4;
        if(loader.findItem("General","hiddenApplications")->property().toStringList()
           != QStringList{"org.kde.kate.desktop", "kitty.desktop"}
           || loader.findItem("General","islandWeatherCity")->property().toString() != QStringLiteral("İstanbul, Türkiye")
           || loader.findItem("General","islandWeatherLocationQuery")->property().toString() != QStringLiteral("İstanbul, Türkiye")
           || loader.findItem("General","islandWeatherLatitude")->property().toString() != "41.01"
           || loader.findItem("General","islandWeatherLongitude")->property().toString() != "28.98") return 6;
        loader.save(); // Startup/save must not restore defaults over explicit false.
    }
    config->reparseConfiguration();
    if(KConfigGroup(config,"General").readEntry("confirmPowerActions",true))return 5;
    return 0;
}
