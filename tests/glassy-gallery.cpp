// Real Qt Widgets gallery and state matrix. Test executable, never installed.
#include <QtWidgets>
#include <QtTest/QTest>
#include <QStyleOptionButton>
#include <QStyleOptionComboBox>
#include <QStyleOptionFrame>
#include <QStyleOptionTab>

class States : public QWidget {
public:
    explicit States(QWidget *parent=nullptr) : QWidget(parent) { setMinimumHeight(286); }
    QSize sizeHint() const override { return {1050,300}; }
    void paintEvent(QPaintEvent *) override {
        QPainter p(this);
        QStringList names={"Normal", "Hover", "Pressed", "Focus", "Checked", "Disabled"};
        for (int c=0;c<6;++c) {
            const int x=c*width()/6;
            p.setPen(palette().windowText().color()); p.drawText(x+8,20,names[c]);
            QStyle::State state=QStyle::State_Active|QStyle::State_Raised;
            if (c!=5) state|=QStyle::State_Enabled;
            if (c==1) state|=QStyle::State_MouseOver;
            if (c==2) state|=QStyle::State_Sunken;
            if (c==3) state|=QStyle::State_HasFocus|QStyle::State_KeyboardFocusChange;
            if (c==4) state|=QStyle::State_On|QStyle::State_Selected;
            QStyleOptionButton b; b.initFrom(this); b.state=state; b.text="Button"; b.rect={x+8,30,width()/6-16,34};
            b.styleObject=nullptr;
            if(c==5)b.palette.setCurrentColorGroup(QPalette::Disabled);
            style()->drawControl(QStyle::CE_PushButton,&b,&p,nullptr);
            QStyleOptionFrame f; f.initFrom(this); f.state=state; f.rect={x+8,76,width()/6-16,34}; f.lineWidth=1;
            f.styleObject=nullptr;
            style()->drawPrimitive(QStyle::PE_PanelLineEdit,&f,&p,nullptr);
            p.drawText(f.rect.adjusted(10,0,-10,0),Qt::AlignVCenter,"Input");
            QStyleOptionComboBox cb; cb.initFrom(this); cb.state=state; cb.rect={x+8,122,width()/6-16,34}; cb.currentText="Combo";
            cb.styleObject=nullptr;
            style()->drawComplexControl(QStyle::CC_ComboBox,&cb,&p,nullptr); style()->drawControl(QStyle::CE_ComboBoxLabel,&cb,&p,nullptr);
            b.rect={x+8,168,width()/6-16,24}; b.text="Check";
            style()->drawControl(QStyle::CE_CheckBox,&b,&p,nullptr);
            b.rect.translate(0,32); b.text="Radio"; style()->drawControl(QStyle::CE_RadioButton,&b,&p,nullptr);
            QStyleOptionTab t; t.initFrom(this); t.state=state; t.rect={x+8,240,width()/6-16,34}; t.text="Tab";
            t.shape=QTabBar::RoundedNorth; t.position=QStyleOptionTab::OnlyOneTab;
            t.styleObject=nullptr;
            style()->drawControl(QStyle::CE_TabBarTab,&t,&p,nullptr);
        }
    }
};

int main(int argc,char **argv) {
    QApplication app(argc,argv);
    QMainWindow window; window.setWindowTitle("Glassy Qt Widgets gallery");
    auto *file=window.menuBar()->addMenu("File"); file->addAction("New"); file->addAction("Open"); file->addSeparator();
    file->addAction("Checked action")->setCheckable(true); file->actions().last()->setChecked(true);
    file->addAction("Disabled action")->setEnabled(false);
    auto *tb=window.addToolBar("Tools"); tb->addAction(app.style()->standardIcon(QStyle::SP_DirHomeIcon),"Home");
    auto *tool=new QToolButton; tool->setText("Options"); tool->setMenu(file); tool->setPopupMode(QToolButton::MenuButtonPopup); tb->addWidget(tool);
    auto *tabs=new QTabWidget; window.setCentralWidget(tabs);
    auto *page=new QWidget; auto *layout=new QVBoxLayout(page); layout->setSpacing(14); layout->setContentsMargins(16,16,16,16);
    layout->addWidget(new States);
    auto *group=new QGroupBox("Controls"); auto *grid=new QGridLayout(group); grid->setHorizontalSpacing(18); grid->setVerticalSpacing(12);
    auto *edit=new QLineEdit("Editable text"); grid->addWidget(edit,0,0);
    auto *combo=new QComboBox; combo->addItems({"First choice","Second choice","Longer third choice"}); grid->addWidget(combo,0,1);
    auto *editable=new QComboBox; editable->setEditable(true); editable->addItems({"Editable combo","Another item"}); grid->addWidget(editable,0,2);
    auto *spin=new QSpinBox; spin->setRange(-100,100); spin->setValue(42); grid->addWidget(spin,0,3);
    auto *check=new QCheckBox("Mixed check"); check->setTristate(true); check->setCheckState(Qt::PartiallyChecked); grid->addWidget(check,1,0);
    auto *radio=new QRadioButton("Selected radio"); radio->setChecked(true); grid->addWidget(radio,1,1);
    auto *slider=new QSlider(Qt::Horizontal); slider->setValue(55); grid->addWidget(slider,1,2);
    auto *progress=new QProgressBar; progress->setValue(70); grid->addWidget(progress,1,3);
    auto *scroll=new QScrollBar(Qt::Horizontal); scroll->setRange(0,100); scroll->setPageStep(30); grid->addWidget(scroll,2,0,1,2);
    auto *dialogButton=new QPushButton("Open dialog"); grid->addWidget(dialogButton,2,2);
    auto *tip=new QPushButton("Tooltip target"); tip->setToolTip("Glassy tooltip — readable palette text"); grid->addWidget(tip,2,3);
    layout->addWidget(group);
    auto *nested=new QTabWidget; nested->setTabsClosable(true); nested->addTab(new QTextEdit("QTextEdit\nSelectable foreground text stays opaque."),"Document"); nested->addTab(new QWidget,"Second tab"); layout->addWidget(nested);
    // Keep the fixed-size state matrix usable when KWin tiles/resizes the
    // gallery below its preferred height. Do not squeeze rows over controls.
    auto *scroller=new QScrollArea; scroller->setFrameShape(QFrame::NoFrame);
    scroller->setWidgetResizable(true); scroller->setWidget(page);
    page->setAutoFillBackground(false); scroller->viewport()->setAutoFillBackground(false);
    tabs->addTab(scroller,"Widgets and states");
    auto *views=new QWidget; auto *row=new QHBoxLayout(views);
    auto *tree=new QTreeWidget; tree->setHeaderLabels({"Name","Value"});
    for (int i=0;i<20;++i) { auto *item=new QTreeWidgetItem(tree,{QString("Folder %1").arg(i),"Data"}); new QTreeWidgetItem(item,{"Child","Value"}); }
    tree->expandItem(tree->topLevelItem(0)); tree->setCurrentItem(tree->topLevelItem(1)); row->addWidget(tree);
    auto *list=new QListWidget; for(int i=0;i<40;++i)list->addItem(QString("List item %1").arg(i)); list->setCurrentRow(2); row->addWidget(list);
    auto *table=new QTableWidget(20,3); table->setHorizontalHeaderLabels({"Column A","Column B","Column C"});
    for(int r=0;r<20;++r)for(int c=0;c<3;++c)table->setItem(r,c,new QTableWidgetItem(QString("Cell %1,%2").arg(r).arg(c)));
    table->setAlternatingRowColors(true); table->selectRow(2); row->addWidget(table); tabs->addTab(views,"Tree, list, table, headers");
    QObject::connect(dialogButton,&QPushButton::clicked,&window,[&window] {
        auto *d=new QDialog(&window); d->setAttribute(Qt::WA_DeleteOnClose); d->setWindowTitle("Glassy dialog");
        auto *l=new QVBoxLayout(d); l->addWidget(new QLabel("Native Qt dialog, palette text and controls.")); l->addWidget(new QLineEdit("Input"));
        auto *buttons=new QDialogButtonBox(QDialogButtonBox::Ok|QDialogButtonBox::Cancel); l->addWidget(buttons);
        QObject::connect(buttons,&QDialogButtonBox::accepted,d,&QDialog::accept); QObject::connect(buttons,&QDialogButtonBox::rejected,d,&QDialog::reject); d->show();
    });
    window.statusBar()->showMessage("Kvantum / Glassy · native Qt Widgets · no window opacity reduction");
    window.resize(1120,820); window.show();
    QString prefix=qEnvironmentVariable("GLASSY_CAPTURE", "/tmp/glassy-gallery");
    QTimer capture; QObject::connect(&capture,&QTimer::timeout,&window,[&] {
        window.grab().save(prefix+".png");
        QFile info(prefix+".json"); if (!info.open(QIODevice::WriteOnly)) return;
        info.write(QJsonDocument(QJsonObject{{"pid",QCoreApplication::applicationPid()}, {"style",app.style()->objectName()},
            {"window",app.palette().color(QPalette::Window).name()}, {"windowOpacity",window.windowOpacity()},
            {"translucent",window.testAttribute(Qt::WA_TranslucentBackground)}, {"dpr",window.devicePixelRatioF()}}).toJson());
    }); capture.start(1500);
    if(qEnvironmentVariableIsSet("GLASSY_AUTO")) {
        QTimer::singleShot(2000,&window,[&]{tabs->setCurrentIndex(1);});
        QTimer::singleShot(2700,&window,[&]{window.grab().save(prefix+"-views.png"); tabs->setCurrentIndex(0); file->popup(window.mapToGlobal(QPoint(100,100)));});
        QTimer::singleShot(3400,&window,[&]{file->grab().save(prefix+"-menu.png"); file->close(); dialogButton->click();});
        QTimer::singleShot(4100,&window,[&]{for(auto *w:app.topLevelWidgets()) if(qobject_cast<QDialog*>(w)&&w->isVisible()){w->grab().save(prefix+"-dialog.png");w->close();}});
        QTimer::singleShot(4500,&window,[&]{QToolTip::showText(window.mapToGlobal(QPoint(100,100)),tip->toolTip(),&window);
            for(auto *w:app.topLevelWidgets()) if(w->windowType()==Qt::ToolTip)w->grab().save(prefix+"-tooltip.png");});
        QTimer::singleShot(5000,&window,[&]{QToolTip::hideText();combo->showPopup();});
        QTimer::singleShot(5100,&window,[&]{combo->view()->window()->grab().save(prefix+"-combo.png");});
        QTimer::singleShot(5400,&window,[&]{combo->hidePopup();});
        QTimer::singleShot(5800,&app,&QApplication::quit);
    }
    return app.exec();
}
