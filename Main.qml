import QtQuick
import QtQuick.Controls
import "page" as Page

Window {
    id: root
    width: 640
    height: 480
    visible: true
    title: qsTr("Hello World")

    StackView {
        id: stack
        initialItem: welcome_page
        anchors.fill: parent
    }

    Component {
        id: welcome_page
    Page.Welcome {
        anchors.fill: parent
        stackView: stack
        }
    }

}
