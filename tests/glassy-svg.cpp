// Test-only SVG geometry probe; uses the same renderer as Kvantum.
#include <QApplication>
#include <QSvgRenderer>
#include <QPainter>
#include <QDebug>
int main(int argc, char **argv) {
    QApplication app(argc, argv);
    QSvgRenderer svg(QString::fromLocal8Bit(argv[1]));
    if (!svg.isValid()) return 2;
    const int configuredRadius=argc>3 ? QString::fromLocal8Bit(argv[3]).toInt() : 4;
    const int scrollRadius=argc>4 ? QString::fromLocal8Bit(argv[4]).toInt() : configuredRadius;
    for (const auto &kind : {"button", "input", "tab", "menu", "tooltip", "scroll", "groove", "progress", "header"}) {
        const QString control(kind);
        const int radius=qMax(1,control=="groove" || control=="progress" || control=="header" ? qMin(configuredRadius,2) : control=="scroll" ? scrollRadius : configuredRadius);
        for(const auto &state : {"normal","focused","pressed","toggled","disabled"}) {
            for(const auto &part : {"topleft","topright","bottomleft","bottomright","top","bottom","left","right"}) {
                const QString id=QString(kind)+"-"+state+"-"+part;
                const auto bounds=svg.boundsOnElement(id);
                const QString side(part);
                const QSizeF expected(side=="top"||side=="bottom"?8:radius,side=="left"||side=="right"?8:radius);
                if(!svg.elementExists(id) || qAbs(bounds.width()-expected.width())>0.001 || qAbs(bounds.height()-expected.height())>0.001) {
                    fprintf(stderr,"Invalid slice: %s (%g x %g)\n",qPrintable(id),bounds.width(),bounds.height()); return 3;
                }
            }
        }
    }
    QImage image(420, 200, QImage::Format_ARGB32_Premultiplied); image.fill(QColor("#777777"));
    QPainter p(&image);
    for (const auto &part : {"topleft", "top", "topright", "left", "right", "bottomleft", "bottom", "bottomright"}) {
        const auto b=svg.boundsOnElement(QString("button-normal-") + part);
        fprintf(stdout,"%s: %g,%g %gx%g\n",part,b.x(),b.y(),b.width(),b.height());
    }
    const QString names[] = {"topleft", "top", "topright", "left", "", "right", "bottomleft", "bottom", "bottomright"};
    int i=0;
    for (auto name : names) {
        svg.render(&p, "button-normal" + (name.isEmpty() ? "" : "-" + name), QRectF(10+(i%3)*64, 10+(i/3)*60, 48,48)); ++i;
    }
    p.end(); image.save(QString::fromLocal8Bit(argv[2]));
    fprintf(stdout,"PASS: exact geometry for all nine-slice control states.\n");
}
