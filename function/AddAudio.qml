import QtQuick 2.15
import QtQuick.Dialogs
import QtQuick.Layouts 1.15
import QtCore

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property var stackView

    ListModel {
        id: list_data
    }

    function get_extension(filename) {
        if (!filename)
            return '';
        console.debug("get_extension():", filename);
        const idx = filename.lastIndexOf('.');
        if (idx === -1 || idx === 0)
            return '';
        return filename.slice(idx + 1);
    }
    function get_path_name(path) {
        path = cmd.cvt_file_url_to_local(path);
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

            delegate: Rectangle {
                id: delegate_root
                width: listview.width
                height: 40
                border.width: 1
                radius: 5
                border.color: "gray"

                RowLayout {
                    anchors.fill: parent

                    Text {
                        Layout.preferredHeight: parent.height / 3
                        Layout.alignment: Qt.AlignVCenter
                        text: get_path_name(name)
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
                text_: qsTr("选择音频")
                onClicked: {
                    audio_path_select.open();
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
            cmd.push_ffmpeg_cmd(`ffmpeg -i "${in_path}" -i "${cmd.cvt_file_url_to_local(list_data.get(0).name)}" -filter_complex "[0:a][1:a]amix=2[a]" -map "0:v" -map "[a]" ${out_path}`);
            cmd.save_ffmpeg_cmd();
            cmd.exec_ffmpeg();
        }
    }

    FileDialog {
        id: audio_path_select
        title: qsTr("选择需要添加的音频")
        fileMode: FileDialog.OpenFile
        currentFile: {
            let ext = get_extension(root.input_video_path);
            if (ext !== '')
                return "out." + ext;
            return "out.mp3";
        }
        currentFolder: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
        nameFilters: [qsTr("音频文件 (*.mp3 *.wav *.aac *.flac *.ogg *.oga *.m4a *.wma *.opus *.ape *.ac3 *.eac3 *.dts *.amr *.aiff *.aif *.au *.ra *.mka *.tta *.wv *.caf *.dsf *.dff *.spx *.gsm *.voc *.mid *.midi *.pcm *.alac *.mp2 *.mp1 *.weba *.oga)"), qsTr("所有文件 (*)")]
        onAccepted: {
            list_data.append({
                "name": audio_path_select.selectedFile.toString()
            });
        }
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
