pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "page" as Page

Window {
    id: root
    width: 640
    height: 480
    visible: true
    title: qsTr("easyCut")

    StackView {
        id: stack
        initialItem: welcome_page
        anchors.fill: parent
    }

    Page.Welcome {
        id: welcome_page
        stackView: stack
    }
}
