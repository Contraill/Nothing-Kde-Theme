import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import "."
Item {
    id: popup

    signal closed
    property var panelConfig: Plasmoid.configuration

    // Holidays and moon phases come from Plasma's own calendar event plugins.
    readonly property var plugins: panelConfig?.calendarEvents ?? ["holidaysevents"]
    function togglePlugin(id) {
        if (!panelConfig) return;
        const list = popup.plugins.filter(p => p !== id);
        if (list.length === popup.plugins.length) list.push(id);
        panelConfig.calendarEvents = list;
    }
    PlasmaCalendar.EventPluginsManager {
        id: eventPlugins
        enabledPlugins: popup.plugins
    }
    PlasmaCalendar.Calendar {
        id: backend
        days: 7
        weeks: 6
        firstDayOfWeek: popup.primerDia
        today: popup.hoy
        displayedDate: new Date(popup.verAnio, popup.verMes, 1)
        Component.onCompleted: daysModel.setPluginsManager(eventPlugins)
    }
    property int eventRev: 0
    Connections {
        target: backend.daysModel
        function onAgendaUpdated() { popup.eventRev++; }
        function onModelReset() { popup.eventRev++; }
    }
    function eventsOn(d) {
        const update = popup.eventRev;
        return backend.daysModel.eventsForDate(d);
    }

    implicitHeight: col.implicitHeight + 44
    property date hoy: new Date()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            const ahora = new Date();
            if (ahora.getDate() !== popup.hoy.getDate() || ahora.getMonth() !== popup.hoy.getMonth() || ahora.getFullYear() !== popup.hoy.getFullYear())
                popup.hoy = ahora;
        }
    }
    property int verMes: hoy.getMonth()
    property int verAnio: hoy.getFullYear()
    property date elegido: new Date(NaN)
    readonly property bool haySeleccion: !isNaN(elegido.getTime())
    property bool eligiendoMes: false

    readonly property var loc: Cfg.locale
    readonly property int primerDia: loc.firstDayOfWeek

    function mover(meses) {
        let m = popup.verMes + meses;
        let a = popup.verAnio;
        while (m < 0) {
            m += 12;
            a--;
        }
        while (m > 11) {
            m -= 12;
            a++;
        }
        popup.verMes = m;
        popup.verAnio = a;
    }

    function volverAHoy() {
        popup.verMes = popup.hoy.getMonth();
        popup.verAnio = popup.hoy.getFullYear();
        popup.elegido = new Date(popup.hoy.getFullYear(), popup.hoy.getMonth(), popup.hoy.getDate());
        popup.eligiendoMes = false;
    }

    function mismoDia(a, b) {
        return a.getDate() === b.getDate() && a.getMonth() === b.getMonth() && a.getFullYear() === b.getFullYear();
    }
    function semanaDe(d) {
        const x = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        const dia = (x.getDay() + 6) % 7;     // lunes = 0
        x.setDate(x.getDate() - dia + 3);     // jueves de esta semana
        const primerJueves = new Date(x.getFullYear(), 0, 4);
        const dia2 = (primerJueves.getDay() + 6) % 7;
        primerJueves.setDate(primerJueves.getDate() - dia2 + 3);
        return 1 + Math.round((x - primerJueves) / (7 * 24 * 3600 * 1000));
    }
    readonly property var dias: {
        const primero = new Date(popup.verAnio, popup.verMes, 1);
        let corrimiento = primero.getDay() - popup.primerDia;
        if (corrimiento < 0)
            corrimiento += 7;

        const salida = [];
        for (var i = 0; i < 42; i++) {
            const d = new Date(popup.verAnio, popup.verMes, 1 - corrimiento + i);
            salida.push({
                fecha: d,
                dia: d.getDate(),
                esteMes: d.getMonth() === popup.verMes
            });
        }
        return salida;
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10
        Item {
            width: parent.width
            height: 26

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Cfg.t("CALENDAR")
                color: Theme.fgFaint
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.letterSpacing: Theme.labelSpacing
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Repeater {
                    model: [{id: "holidaysevents", icon: "celebration", label: "HOLIDAYS"},
                        {id: "astronomicalevents", icon: "bedtime", label: "MOON PHASES"}]
                    Rectangle {
                        id: chip
                        required property var modelData
                        readonly property bool on: popup.plugins.includes(modelData.id)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        radius: height / 2
                        color: on ? Theme.inverted : chipMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                        Accessible.role: Accessible.CheckBox
                        Accessible.name: Cfg.t(modelData.label)
                        Accessible.checked: on

                        Text {
                            anchors.centerIn: parent
                            text: chip.modelData.icon
                            color: chip.on ? Theme.invertedFg : Theme.fgDim
                            font.family: Theme.fontIcons
                            font.pixelSize: 15
                        }
                        MouseArea {
                            id: chipMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.togglePlugin(chip.modelData.id)
                        }
                    }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: hoyTxt.implicitWidth + 20
                    height: 26
                    radius: height / 2
                    color: hoyMa.containsMouse ? Theme.inverted : Theme.surfaceAlt
                    visible: popup.verMes !== popup.hoy.getMonth() || popup.verAnio !== popup.hoy.getFullYear()

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durShort
                        }
                    }

                    Text {
                        id: hoyTxt
                        anchors.centerIn: parent
                        text: Cfg.t("TODAY")
                        color: hoyMa.containsMouse ? Theme.invertedFg : Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.labelSmall
                        font.letterSpacing: Theme.labelSpacing
                    }

                    MouseArea {
                        id: hoyMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.volverAHoy()
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: height / 2
                    color: closeMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durShort
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        color: closeMa.containsMouse ? Theme.fg : Theme.fgDim
                        font.family: Theme.fontIcons
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.closed()
                    }
                }
            }
        }
        component Flecha: Rectangle {
            id: fl
            property string icono: ""
            signal apretada

            width: 30
            height: 30
            radius: height / 2
            color: fMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durShort
                }
            }

            Text {
                anchors.centerIn: parent
                text: fl.icono
                color: fMa.containsMouse ? Theme.fg : Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 20
            }

            MouseArea {
                id: fMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: fl.apretada()
            }
        }

        Item {
            width: parent.width
            height: 34

            Flecha {
                id: atras
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                icono: "chevron_left"
                onApretada: popup.eligiendoMes ? popup.verAnio-- : popup.mover(-1)
            }
            Rectangle {
                anchors.left: atras.right
                anchors.right: adelante.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                height: 32
                radius: height / 2
                color: tituloMa.containsMouse || popup.eligiendoMes ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (popup.eligiendoMes)
                            return String(popup.verAnio);
                        const d = new Date(popup.verAnio, popup.verMes, 1);
                        return (popup.loc.standaloneMonthName(d.getMonth(), Locale.LongFormat) + " " + popup.verAnio).toLocaleUpperCase(popup.loc.name);
                    }
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodyMedium
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.labelSpacing
                }

                MouseArea {
                    id: tituloMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.eligiendoMes = !popup.eligiendoMes
                }
            }

            Flecha {
                id: adelante
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icono: "chevron_right"
                onApretada: popup.eligiendoMes ? popup.verAnio++ : popup.mover(1)
            }
        }
        Item {
            width: parent.width
            height: 214
            clip: true
            Column {
                id: vistaDias
                width: parent.width
                spacing: 4

                opacity: popup.eligiendoMes ? 0 : 1
                visible: opacity > 0
                y: popup.eligiendoMes ? -14 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durShort
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasizedDecel
                    }
                }
                Row {
                    width: parent.width

                    Repeater {
                        model: 7

                        Text {
                            required property int index
                            width: vistaDias.width / 7
                            height: 22
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: {
                                const d = (popup.primerDia + index) % 7;
                                return popup.loc.dayName(d, Locale.ShortFormat).substring(0, 2).toLocaleUpperCase(popup.loc.name);
                            }
                            color: Theme.fgFaint
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            font.letterSpacing: Theme.labelSpacing
                        }
                    }
                }
                Grid {
                    width: parent.width
                    columns: 7
                    rows: 6

                    Repeater {
                        model: popup.dias

                        Item {
                            id: celda
                            required property var modelData
                            required property int index

                            width: vistaDias.width / 7
                            height: 30

                            readonly property bool esHoy: popup.mismoDia(modelData.fecha, popup.hoy)
                            readonly property bool esElegido: popup.haySeleccion && popup.mismoDia(modelData.fecha, popup.elegido)
                            readonly property bool hayEvento: popup.eventsOn(modelData.fecha).length > 0

                            Rectangle {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                radius: height / 2
                                color: celda.esHoy ? Theme.inverted : dMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)
                                border.width: celda.esElegido && !celda.esHoy ? 1.5 : 0
                                border.color: Theme.fgDim

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.durShort
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: celda.modelData.dia
                                    color: {
                                        if (celda.esHoy)
                                            return Theme.invertedFg;
                                        return celda.modelData.esteMes ? Theme.fg : Theme.fgFaint;
                                    }
                                    font.family: Theme.fontDots
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2
                                    width: 4
                                    height: 4
                                    radius: 2
                                    visible: celda.hayEvento
                                    color: celda.esHoy ? Theme.invertedFg : Theme.primary
                                    opacity: celda.modelData.esteMes ? 1 : 0.4
                                }

                                MouseArea {
                                    id: dMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        popup.elegido = celda.modelData.fecha;
                                        if (!celda.modelData.esteMes) {
                                            popup.verMes = celda.modelData.fecha.getMonth();
                                            popup.verAnio = celda.modelData.fecha.getFullYear();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Grid {
                id: vistaMeses
                width: parent.width
                columns: 4
                rows: 3

                opacity: popup.eligiendoMes ? 1 : 0
                visible: opacity > 0
                y: popup.eligiendoMes ? 0 : 14

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durShort
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasizedDecel
                    }
                }

                Repeater {
                    model: 12

                    Item {
                        id: mesItem
                        required property int index
                        width: vistaMeses.width / 4
                        height: 66

                        readonly property bool esteMes: index === popup.hoy.getMonth() && popup.verAnio === popup.hoy.getFullYear()

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            height: 54
                            radius: Theme.shapeMd
                            color: {
                                if (mesItem.index === popup.verMes)
                                    return Theme.inverted;
                                return mMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt;
                            }
                            border.width: mesItem.esteMes && mesItem.index !== popup.verMes ? 1.5 : 0
                            border.color: Theme.fgDim

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durShort
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: popup.loc.standaloneMonthName(mesItem.index, Locale.ShortFormat).toLocaleUpperCase(popup.loc.name)
                                color: mesItem.index === popup.verMes ? Theme.invertedFg : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.bodySmall
                                font.weight: Font.Medium
                                font.letterSpacing: Theme.labelSpacing
                            }

                            MouseArea {
                                id: mMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    popup.verMes = mesItem.index;
                                    popup.eligiendoMes = false;
                                }
                            }
                        }
                    }
                }
            }
        }
        Rectangle {
            id: pie
            width: parent.width
            height: Math.max(46, pieCol.implicitHeight + 16)
            radius: Theme.shapeLg
            color: Theme.surfaceAlt

            readonly property date foco: popup.haySeleccion ? popup.elegido : popup.hoy
            readonly property string eventos: popup.eventsOn(foco).map(e => e.title).join(" · ")

            Text {
                id: numGrande
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: pie.foco.getDate()
                color: Theme.fg
                font.family: Theme.fontDots
                font.pixelSize: 24
                font.weight: Font.Bold
            }

            Column {
                id: pieCol
                anchors.left: numGrande.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: popup.loc.dayName(pie.foco.getDay(), Locale.LongFormat).toLocaleUpperCase(popup.loc.name)
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.labelMedium
                    font.letterSpacing: Theme.labelSpacing
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: {
                        const f = pie.foco;
                        const mes = popup.loc.standaloneMonthName(f.getMonth(), Locale.LongFormat);
                        return (mes + " " + f.getFullYear() + " · " + Cfg.t("Week") + " " + popup.semanaDe(f)).toLocaleUpperCase(popup.loc.name);
                    }
                    color: Theme.fgFaint
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    font.letterSpacing: Theme.labelSpacing
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: pie.eventos.toLocaleUpperCase(popup.loc.name)
                    color: Theme.primary
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    font.letterSpacing: Theme.labelSpacing
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }
    }
}
