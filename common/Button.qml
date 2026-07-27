import QtQuick 2.15

Rectangle {
    id: button
    property int radius_: 10
    property string text_: qsTr("button")
    signal clicked

    radius: radius_
    border.color: "gray"
    // color: "#f0c8dc"
    scale: 1.0

    implicitWidth: 220
    implicitHeight: 80

    Text {
        anchors.centerIn: parent
        text: button.text_
    }

    Behavior on scale {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuad
        }
    }

    MouseArea {
        id: mou
        anchors.fill: parent
        hoverEnabled: true

        onEntered: button.scale = 0.9
        onExited: button.scale = 1.0
        onPressed: button.scale = 0.6
        onReleased: button.scale = containsMouse ? 0.9 : 1.0
        onClicked: button.clicked()
    }
}
