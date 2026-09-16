// A removable test window, not a wallpaper change or an installed component.
#include <QApplication>
#include <QPainter>
#include <QWidget>
class Backdrop : public QWidget {
    void paintEvent(QPaintEvent *) override {
        QPainter p(this);
        for (int y=0; y<height(); y+=16) for (int x=0; x<width(); x+=16)
            p.fillRect(x,y,16,16, ((x/16+y/16)%2) ? QColor(220,190,140) : QColor(40,110,150));
    }
public:
    Backdrop() { setWindowTitle("Nothing appearance test backdrop"); setWindowFlags(Qt::Window | Qt::FramelessWindowHint);
        setAttribute(Qt::WA_OpaquePaintEvent); resize(1400,900); move(100,60); }
};
int main(int argc,char **argv) { QApplication app(argc,argv); Backdrop window; window.show(); return app.exec(); }
