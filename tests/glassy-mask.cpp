// Verify actual KSvg QRegions, not just SVG element names.
#include <QApplication>
#include <KSvg/FrameSvg>
#include <cstdio>
int main(int argc,char **argv) {
    QApplication app(argc,argv);
    if(argc!=2)return 2;
    KSvg::FrameSvg svg;
    svg.setImagePath(QString::fromLocal8Bit(argv[1]));
    // Reuse one renderer, exactly as the live QML item does when Apply changes
    // its prefix. Test both directions and blur off/on to catch stale masks.
    for (const QSize size : {QSize(400,300), QSize(180,100)}) {
      svg.resizeFrame(size);
      for(const bool bottom : {false,true}) for(int step=0;step<=48;++step) {
        const int radius=step<=24?step:48-step;
        svg.setElementPrefix(QString("%1%2").arg(bottom ? "b" : "r").arg(radius));
        auto mask=svg.mask();
        const QPoint center(size.width()/2,30);
        if(mask.boundingRect()!=QRect(12,12,size.width()-24,size.height()-24)
           || !mask.contains(center) || mask.contains(QPoint(1,1))
           || (radius>=10 && (mask.contains(QPoint(12,12)) || mask.contains(QPoint(size.width()-13,12))))
           || (radius==0 && !mask.contains(QPoint(12,12)))
           || (bottom && radius>=10 && mask.contains(QPoint(12,size.height()-13)))
           || ((!bottom || radius==0) && !mask.contains(QPoint(12,size.height()-13)))) {
            const auto b=mask.boundingRect();
            fprintf(stderr,"FAIL: radius %d mask; bounds %d,%d %dx%d center=%d shadow=%d corner=%d\n",radius,
                b.x(),b.y(),b.width(),b.height(),mask.contains(center),mask.contains(QPoint(1,1)),mask.contains(QPoint(12,12)));
            svg.alphaMask().save("/tmp/glassy-mask-failure.png"); return 3;
        }
        svg.setElementPrefix(QStringLiteral("off"));
        if(!svg.mask().isEmpty()) {fprintf(stderr,"FAIL: blur-off mask is not empty\n");return 4;}
      }
    }
    fprintf(stdout,"PASS: native KSvg masks, radius 0..24..0, resize and blur off/on.\n");
}
