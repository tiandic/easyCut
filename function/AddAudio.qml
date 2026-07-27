pragma ComponentBehavior: Bound

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

    function check_input(text) {
        let l;
        if (text == "")
            return qsTr("输入不可为空!");
        else if (text.split(',') > 2)
            return qsTr("输入最多只能有一个逗号!");
        else if (!(l = check_limit(text, "1234567890,:"))[0])
            return qsTr(`输入不应包含字符 '${l[1]}'`);
        return "";
    }

    function check_limit(text, limit_chars) {
        for (let i = 0; i < text.length; i++) {
            if (limit_chars.indexOf(text[i]) == -1)
                return [false, text[i]];
        }
        return [true, ""];
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
    function cvt_time_to_ms(t) {
        // 转换标准时间格式为毫秒数
        // 支持如下格式:
        // 4:11:40 or 4:11:40,560 or 11:11 or 11:11,700 or 12,560 or 4 (只输入一个数字默认为秒)
        let ms = 0;
        let i; // 计算到了第几位

        if (t.indexOf(',') != -1) {
            let t_and_ms = t.split(",");
            t = t_and_ms[0];
            ms = parseInt(t_and_ms[1]);
        }
        for (i = 0; (i <= 2 && t.indexOf(':') != -1); i++) {
            let t2_list = t.split(":");
            ms += parseInt(t2_list.pop()) * (60 ** i) * 1000;
            t = t2_list.join(':');
        }
        ms += parseInt(t) * (60 ** i) * 1000;
        return ms;
    }

    ColumnLayout {
        id: input
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        width: 320
        spacing: 5

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

                required property string name

                RowLayout {
                    anchors.fill: parent

                    Text {
                        Layout.preferredHeight: parent.height / 3
                        Layout.alignment: Qt.AlignVCenter
                        text: root.get_path_name(delegate_root.name)
                    }
                }
            }

            anchors {
                leftMargin: width / 9
                topMargin: width / 12
            }
        }

        Com.LabelInput2 {
            id: input_start_time
            Layout.fillWidth: true
            label: qsTr("开始播放时间")
            text: '00:00:00,000'
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
                    let m = root.check_input(input_start_time.text);
                    if (!audio_path_select.selected_file) {
                        msg.text = qsTr("请先选择需要添加的音频文件!");
                        msg.open();
                    } else if (m != "") {
                        msg.text = m;
                        msg.open();
                    } else {
                        save_path_select.dialog.open();
                    }
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
            cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" -i "${cmd.cvt_file_url_to_local(list_data.get(0).name)}" -filter_complex "[1:a]adelay=${cvt_time_to_ms(input_start_time.text)}:all=1[adelay_audio];[0:a][adelay_audio]amix=2:duration=first[a]" -map "0:v" -map "[a]" ${out_path}`);
            cmd.exec_ffmpeg();
        }
    }

    Com.MsgDialog {
        id: msg
    }

    FileDialog {
        id: audio_path_select
        title: qsTr("选择需要添加的音频")
        fileMode: FileDialog.OpenFile
        property bool selected_file: false
        currentFolder: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
        nameFilters: [qsTr("音频文件 (*.mp3 *.wav *.aac *.flac *.ogg *.oga *.m4a *.wma *.opus *.ape *.ac3 *.eac3 *.dts *.amr *.aiff *.aif *.au *.ra *.mka *.tta *.wv *.caf *.dsf *.dff *.spx *.gsm *.voc *.mid *.midi *.pcm *.alac *.mp2 *.mp1 *.weba *.oga)"), qsTr("所有文件 (*)")]
        onAccepted: {
            selected_file = true;
            list_data.append({
                "name": audio_path_select.selectedFile.toString()
            });
        }
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
