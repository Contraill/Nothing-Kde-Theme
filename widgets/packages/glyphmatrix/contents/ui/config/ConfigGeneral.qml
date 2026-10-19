// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "../../../../../shared" as Glassy
import "../matrix.js" as Matrix

KCM.SimpleKCM {
    id: page
    property int cfg_widgetVariant
    property string cfg_drawing
    property alias cfg_picture: pictureField.text
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome
    property alias cfg_transparent: theme.transparent

    // "#" a dot, "+" an accent dot, "." the eraser.
    property string pen: "#"
    readonly property string drawing: cfg_drawing.length === 625 ? cfg_drawing : ".".repeat(625)
    function paint(index) {
        if (index < 0 || index >= 625 || drawing.charAt(index) === pen) return;
        cfg_drawing = drawing.slice(0, index) + pen + drawing.slice(index + 1);
    }

    ColumnLayout {
        spacing: 10
        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: page.cfg_widgetVariant
            onPicked: value => page.cfg_widgetVariant = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: [
                {label: i18n("Drawing"), value: 0, frame: Matrix.fromDrawing(page.drawing)},
                {label: i18n("Clock"), value: 1, frame: Matrix.clock(new Date(2026, 0, 1, 10, 9, 15), true)},
                {label: i18n("Pulse"), value: 2, frame: Matrix.pulse(0.6)},
                {label: i18n("Radar"), value: 3, frame: Matrix.radar(1.2)},
                {label: i18n("Rain"), value: 4, frame: Matrix.rain(2.0)},
                {label: i18n("Life"), value: 5, frame: Matrix.life(null)},
                {label: i18n("Picture"), value: 6, frame: Matrix.fromDrawing(page.drawing), picture: page.pictureUrl}
            ].map(s => ({label: s.label, value: s.value, source: Qt.resolvedUrl("../GlyphMatrix.qml"),
                         props: {frame: s.frame, picture: s.picture ?? ""}}))
        }

        // The drawing: click or drag over the dots.
        RowLayout {
            visible: page.cfg_widgetVariant === 0
            spacing: 16
            Rectangle {
                id: board
                Layout.preferredWidth: 300
                Layout.preferredHeight: 300
                radius: width / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.04)
                readonly property real cell: width / Matrix.size
                Repeater {
                    model: Matrix.size * Matrix.size
                    Rectangle {
                        required property int index
                        readonly property int column: index % Matrix.size
                        readonly property int row: Math.floor(index / Matrix.size)
                        readonly property string mark: page.drawing.charAt(index)
                        visible: Matrix.inside(column, row)
                        x: (column + 0.12) * board.cell
                        y: (row + 0.12) * board.cell
                        width: board.cell * 0.76
                        height: width
                        radius: width / 2
                        color: mark === "+" ? Kirigami.Theme.highlightColor : mark === "#" ? Kirigami.Theme.textColor : Qt.alpha(Kirigami.Theme.textColor, 0.12)
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    function at(mouse) {
                        const column = Math.floor(mouse.x / board.cell), row = Math.floor(mouse.y / board.cell);
                        if (column >= 0 && row >= 0 && column < Matrix.size && row < Matrix.size && Matrix.inside(column, row))
                            page.paint(row * Matrix.size + column);
                    }
                    onPressed: mouse => at(mouse)
                    onPositionChanged: mouse => { if (pressed) at(mouse) }
                }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                QQC2.RadioButton { text: i18n("Dot"); checked: page.pen === "#"; onToggled: page.pen = "#" }
                QQC2.RadioButton { text: i18n("Accent dot"); checked: page.pen === "+"; onToggled: page.pen = "+" }
                QQC2.RadioButton { text: i18n("Eraser"); checked: page.pen === "."; onToggled: page.pen = "." }
                Item { implicitHeight: 8 }
                QQC2.Button { text: i18n("Clear"); icon.name: "edit-clear"; onClicked: page.cfg_drawing = ".".repeat(625) }
                QQC2.Button {
                    text: i18n("Invert")
                    icon.name: "edit-select-invert"
                    onClicked: page.cfg_drawing = page.drawing.split("").map((c, i) => !Matrix.inside(i % 25, Math.floor(i / 25)) ? "." : c === "." ? "#" : ".").join("")
                }
                QQC2.Button { text: i18n("From a picture…"); icon.name: "document-open"; onClicked: { pictureDialog.forDrawing = true; pictureDialog.open() } }
            }
        }

        // The picture or animation of the last style.
        RowLayout {
            visible: page.cfg_widgetVariant === 6
            Layout.fillWidth: true
            QQC2.Label { text: i18n("Picture:") }
            QQC2.TextField {
                id: pictureField
                Layout.fillWidth: true
                placeholderText: i18n("A GIF, WebP or PNG; light parts light the dots")
            }
            QQC2.Button { text: i18n("Browse…"); icon.name: "document-open"; onClicked: { pictureDialog.forDrawing = false; pictureDialog.open() } }
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: page.cfg_widgetVariant === 6
            text: i18n("Animations made for the phone's Glyph Matrix can be shown as GIFs; Glyph Toys themselves are Android apps and cannot run here.")
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: 9
        }
        Glassy.ThemeSettings { id: theme; cardOption: true }
    }

    readonly property url pictureUrl: pictureField.text ? (pictureField.text.startsWith("/") ? "file://" + pictureField.text : pictureField.text) : ""
    FileDialog {
        id: pictureDialog
        property bool forDrawing: false
        title: forDrawing ? i18n("Draw from a picture") : i18n("Choose a picture")
        nameFilters: [i18n("Pictures (*.gif *.webp *.png *.jpg *.jpeg *.svg)")]
        onAccepted: {
            const path = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""));
            if (forDrawing) converter.load(selectedFile);
            else pictureField.text = path;
        }
    }
    // A picture to the drawing: its light parts become dots.
    Canvas {
        id: converter
        width: Matrix.size
        height: Matrix.size
        visible: false
        property url source
        function load(url) {
            if (source.toString()) unloadImage(source);
            source = url;
            loadImage(url);
        }
        onImageLoaded: requestPaint()
        onPaint: {
            if (!source.toString() || !isImageLoaded(source)) return;
            const ctx = getContext("2d");
            ctx.reset();
            ctx.drawImage(source, 0, 0, Matrix.size, Matrix.size);
            const data = ctx.getImageData(0, 0, Matrix.size, Matrix.size).data;
            let text = "";
            for (let i = 0; i < 625; ++i) {
                const level = (0.2126 * data[i * 4] + 0.7152 * data[i * 4 + 1] + 0.0722 * data[i * 4 + 2]) / 255 * data[i * 4 + 3] / 255;
                text += Matrix.inside(i % 25, Math.floor(i / 25)) && level > 0.5 ? "#" : ".";
            }
            page.cfg_drawing = text;
        }
    }
}
