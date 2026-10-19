import QtQuick

Item {
    id: marqueeRoot

    // Public properties
    property string text: ""
    property int fontSize: 18
    property bool bold: true
    property string textColor: "white"
    property int scrollSpeed: 20  // pixels per character difference
    property int initialPause: 2000
    property int endPause: 1000
    property bool scrollResetQueued: false

    clip: true

    function queueScrollReset() {
        if (scrollResetQueued) {
            return
        }

        scrollResetQueued = true
        Qt.callLater(function() {
            scrollResetQueued = false
            marqueeAnimation.stop()
            scrollingText.x = 0

            if (scrollingText.needsScrolling) {
                marqueeAnimation.start()
            }
        })
    }

    Component.onCompleted: queueScrollReset()
    onTextChanged: queueScrollReset()
    onWidthChanged: queueScrollReset()

    Text {
        id: scrollingText
        text: marqueeRoot.text
        font.pixelSize: marqueeRoot.fontSize
        font.bold: marqueeRoot.bold
        color: marqueeRoot.textColor

        onWidthChanged: marqueeRoot.queueScrollReset()

        property real scrollDistance: Math.max(0, width - parent.width)
        property bool needsScrolling: scrollDistance > 0

        x: 0

        SequentialAnimation {
            id: marqueeAnimation
            loops: Animation.Infinite

            // Initial pause
            PauseAnimation { duration: marqueeRoot.initialPause }

            // Scroll to the left
            NumberAnimation {
                target: scrollingText
                property: "x"
                from: 0
                to: -scrollingText.scrollDistance
                duration: scrollingText.scrollDistance * marqueeRoot.scrollSpeed
                easing.type: Easing.Linear
            }

            // Pause at the end
            PauseAnimation { duration: marqueeRoot.endPause }

            // Scroll back to the right
            NumberAnimation {
                target: scrollingText
                property: "x"
                from: -scrollingText.scrollDistance
                to: 0
                duration: scrollingText.scrollDistance * marqueeRoot.scrollSpeed
                easing.type: Easing.Linear
            }
        }
    }
}
