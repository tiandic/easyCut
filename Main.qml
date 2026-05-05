import QtQuick
import "page" as Page

Window {
    id: root
    width: 640
    height: 480
    visible: true
    title: qsTr("Hello World")

    Page.Welcome {
        id: welcome_page
        anchors.fill: parent
        }

}
