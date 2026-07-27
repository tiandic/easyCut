pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Layouts
import "../common" as Com

// 功能选择
Item {
    id: root
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
        ListElement {
            name: "AddSubtitles"
            text: qsTr("添加字幕")
        }
        ListElement {
            name: "ExtractAllFrames"
            text: qsTr("提取所有帧")
        }
    }

    ColumnLayout {
        id: func_col
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        width: parent.width / 5

        Item {
            Layout.preferredHeight: 10
        }

        RowLayout {
            Item {
                Layout.preferredWidth: 10
            }
            Com.Button {
                text_: qsTr("← 返回")
                onClicked: root.stackView.pop()
                Layout.preferredWidth: 80
                Layout.preferredHeight: 30
            }
        }

        Item {
            Layout.preferredHeight: 10
        }

        ListView {
            id: listview
            spacing: 10

            Layout.fillWidth: true
            Layout.fillHeight: true

            model: func_list_data

            function goto_function(n) {
                var comp = Qt.createComponent("../function/" + n + ".qml");
                if (comp.status == Component.Ready) {
                    let obj = comp.createObject(null, {
                        video_path: root.video_path,
                        stackView: root.stackView
                    });
                    if (obj == null) {
                        console.log(n + " create failed!");
                        return;
                    }
                    root.stackView.push(obj);
                } else if (comp.status == Component.Error)
                    console.log(comp.errorString());
            }

            delegate: Com.Button {
                id: button
                required property string name
                required property string text
                width: listview.width * 5 / 6
                height: width / 3
                text_: text
                onClicked: listview.goto_function(name)
            }

            anchors {
                leftMargin: width / 9
                topMargin: width / 12
            }
        }
    }

    // 视频播放区域
    Com.VideoPlay {
        id: videoPlay
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: func_col.right

        anchors.rightMargin: 10

        video_path: video_path
    }
    onVideo_pathChanged: videoPlay.video_path = video_path
}
