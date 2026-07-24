import QtQuick 2.15
import "../common" as Com
import "../function" as Funcs

// 功能选择
Item {
    id: select_function
    property string video_path: ""
    property var stackView

    // 功能列表
    ListModel {
        id: func_list_data
        ListElement {
            name: "Cropping"
            text: qsTr("画面裁剪")
        }
        ListElement {
            name: "TimeCrop"
            text: qsTr("时间裁剪")
        }
        ListElement {
            name: "splicing"
            text: qsTr("视频拼接")
        }
        ListElement {
            name: "ExtractAudio"
            text: qsTr("提取音频")
        }
        ListElement {
            name: "AddAudio"
            text: qsTr("添加音频")
        }
    }
    ListView {
        id: listview
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        spacing: 10

        width: parent.width / 5

        model: func_list_data

        function goto_function(n) {
            var comp = Qt.createComponent("../function/" + n + ".qml");
            if (comp.status == Component.Ready) {
                var obj = comp.createObject(null, {
                    video_path: select_function.video_path,
                    stackView: select_function.stackView
                });
                if (obj == null) {
                    console.log(n + " create failed!");
                    return;
                }
                stackView.push(obj);
            } else if (comp.status == Component.Error)
                console.log(comp.errorString());
        }

        delegate: Com.Button {
            id: button
            width: listview.width * 5 / 6
            height: width / 3
            text_: model.text
            onClicked: listview.goto_function(model.name)
        }

        anchors {
            leftMargin: width / 9
            topMargin: width / 12
        }
    }

    // 视频播放区域
    Com.VideoPlay {
        id: videoPlay
        //anchors.fill: parent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: listview.right

        anchors.rightMargin: 10

        video_path: video_path
    }
    onVideo_pathChanged: videoPlay.video_path = video_path
}
