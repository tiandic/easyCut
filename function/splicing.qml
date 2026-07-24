import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import QtCore

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property var stackView

    ListModel {
        id: list_data
    }

    function remove_pre(str, pre) {
        if (str.startsWith(pre)) {
            return str.slice(pre.length);
        }
        return str;
    }

    function get_path_name(path) {
        path = remove_pre(path, "file://");
        let idx = path.lastIndexOf('/');
        if (idx === -1)
            idx = path.lastIndexOf('\\');
        if (idx === -1)
            return path;
        return path.slice(idx + 1);
    }

    ColumnLayout {
        id: input
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        width: 320
        spacing: 5

        Item {
            Layout.preferredHeight: 20
        }

        ListView {
            id: listview
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            width: parent.width / 5

            model: list_data

            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 300
                }
                NumberAnimation {
                    property: "y"
                    from: -20
                    duration: 300
                }
            }

            remove: Transition {
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: 200
                }
            }

            delegate: Rectangle {
                id: delegate_root
                width: listview.width
                height: 40
                border.width: 1
                radius: 5
                border.color: "gray"

                RowLayout {
                    anchors.fill: parent

                    Item {
                        Layout.preferredWidth: 3
                        Layout.alignment: Qt.AlignLeft
                    }

                    Text {
                        Layout.preferredHeight: parent.height / 3
                        Layout.alignment: Qt.AlignLeft
                        text: get_path_name(name)
                    }

                    // Item {
                    // Layout.fillWidth: true
                    // }

                    ListView.onRemove: removeAnim.start()
                    ListView.delayRemove: removeAnim.running
                    SequentialAnimation {
                        id: removeAnim
                        PropertyAction {
                            target: delegate_root
                            property: "ListView.delayRemove"
                            value: true
                        }
                        NumberAnimation {
                            target: delegate_root
                            property: "opacity"
                            to: 0
                            duration: 200
                        }
                        PropertyAction {
                            target: delegate_root
                            property: "ListView.delayRemove"
                            value: false
                        }
                    }

                    Com.Button {
                        Layout.preferredHeight: parent.height / 1.5
                        Layout.preferredWidth: Layout.preferredHeight + 5
                        Layout.alignment: Qt.AlignRight
                        text_: qsTr("X")
                        onClicked: {
                            list_data.remove(index);
                        }
                    }
                    Item {
                        Layout.preferredWidth: 3
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            anchors {
                leftMargin: width / 9
                topMargin: width / 12
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Com.Button {
                Layout.fillWidth: true
                text_: qsTr("选择视频")
                onClicked: {
                    video_select.open();
                }
            }
            Com.Button {
                Layout.fillWidth: true
                text_: qsTr("确认")
                onClicked: {
                    save_path_select.dialog.open();
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }  // 避免 ColumnLayout 自动设置间隔
    }

    Com.VideoPlay {
        id: videoPlay
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: input.right

        anchors.rightMargin: 10
        anchors.leftMargin: 30

        video_path: root.video_path
    }

    Com.SavePathSelect {
        id: save_path_select
        input_video_path: videoPlay.video_path
        onSelected: function (in_path, out_path) {
            let file_path = remove_pre(videoPlay.video_path, "file://");
            let concats = [];
            for (let i = 0; i < list_data.count; i++)
                concats.push(remove_pre(list_data.get(i).name, "file://"));

            let concat_str = `"concat:${concats.join('|')}"`;
            cmd.push_ffmpeg_cmd(`ffmpeg -i ${concat_str} ${out_path}`);
            cmd.save_ffmpeg_cmd();
            cmd.exec_ffmpeg();
        }
    }

    FileDialog {
        id: video_select
        title: qsTr("选择视频文件")
        currentFolder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
        nameFilters: [qsTr("视频文件 (*.mp4 *.m4v *.mkv *.avi *.mov *.qt *.flv *.webm *.mpg *.mpeg *.m2v *.m1v *.mpv *.ts *.mts *.m2ts *.vob *.ogv *.3gp *.3g2 *.str *.4xm *.a64 *.amv *.dv *.yuv *.h264 *.264 *.hevc *.h265 *.vp8 *.vp9 *.prores *.mxf *.cineform *.huff *.ffv1 *.snow *.vp6 *.ogv)"), qsTr("所有文件 (*)")]
        onAccepted: {
            list_data.append({
                "name": video_select.selectedFile.toString()
            });
        }
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
