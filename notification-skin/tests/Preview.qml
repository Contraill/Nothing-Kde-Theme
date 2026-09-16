// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import "../build/com.nothingplasma.notificationbridge/contents/ui/delegates"

Window {
    width: 780
    height: 260
    visible: true
    color: "#292929"
    Row {
        anchors.centerIn: parent
        spacing: 44
        Repeater {
            model: 2
            NothingDelegatePopup {
                required property int index
                width: 320
                lightMode: index === 1
                modelInterface {
                    applicationName: "Mesajlar"
                    summary: "Birazdan oradayım."
                    body: "Kahveleri ben alıyorum. Her zamanki yerde buluşalım."
                    closable: true
                    timeout: 6000
                    remainingTime: 4200
                    popupLeftPadding: 16
                    popupRightPadding: 16
                    popupTopPadding: 16
                    popupBottomPadding: 16
                }
            }
        }
    }
}
