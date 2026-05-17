import QtQuick 2.15
import "../common" as Com

// 功能选择
Item {
    property string video_path: ""

    // 功能列表
    ListModel {
         id: func_list_data
         ListElement {name: "cropping"; text: qsTr("画面裁剪")}
    }
    ListView {
        id: listview
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        width: parent.width/5

        model: func_list_data

        delegate: Com.Button {
            id: button
            width: listview.width *5/6
            height: width/3
            text_: model.text
        }

        anchors {
            leftMargin: width/9
            topMargin: width/12
        }
    }

    // 视频播放区域
    Com.VideoPlay{
        id: videoPlay
        //anchors.fill: parent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: listview.right

        anchors.rightMargin: 10

        video_path: video_path
    }
    onVideo_pathChanged: videoPlay.video_path=video_path

}
