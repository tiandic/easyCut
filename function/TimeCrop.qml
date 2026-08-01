import QtQuick 2.15
import QtQuick.Layouts 1.15

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property var stackView

    // 当输入为 need_most_value_char 时, 指定输入框应该被替换为最值, 最值由输入框的 placeholder 属性决定
    property string need_most_value_char: '-'

    function check_input(text) {
        let l;
        if (text == "")
            return qsTr("输入不可为空!");
        else if (text.split(',') > 2)
            return qsTr("输入最多只能有一个逗号!");
        else if (!(l = check_limit(text, "1234567890,:" + need_most_value_char))[0])
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

    function get_end_subtitles_time() {
        // 获取 srt 时间格式的视频末尾时间
        let t = videoPlay.video_provider.get_total_time();
        // 毫秒
        let ms = (t % 100) * 10;
        t = parseInt(t / 100);
        // 秒
        let s = t % 60;
        t = parseInt(t / 60);
        // 分钟
        let m = t % 60;
        t = parseInt(t / 60);
        // 小时
        let h = t;

        return `${h.toString().padStart(2, 0)}:${m.toString().padStart(2, 0)}:${s.toString().padStart(2, 0)},${ms.toString().padStart(3, 0)}`;
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

        width: 340
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Com.LabelInput2 {
                id: input_start
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("开始时间")
                placeholder: "00:00:00"
            }
            Com.LabelInput2 {
                id: input_end
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("结束时间")
                placeholder: root.get_end_subtitles_time()
            }
        }

        Com.Button {
            Layout.fillWidth: true
            text_: qsTr("确认")
            onClicked: {
                let m;
                if ((m = root.check_input(input_start.text)) != "") {
                    msg.text = qsTr("开始时间格式错误: ") + m;
                    msg.open();
                } else if ((m = root.check_input(input_end.text)) != "") {
                    msg.text = qsTr("结束时间格式错误: ") + m;
                    msg.open();
                } else if (root.cvt_time_to_ms(input_start.text) > root.cvt_time_to_ms(input_end.text)) {
                    msg.text = qsTr("开始时间不能大于结束时间!");
                    msg.open();
                } else if (root.cvt_time_to_ms(input_start.text) == root.cvt_time_to_ms(input_end.text)) {
                    msg.text = qsTr("开始时间不能等于结束时间!");
                    msg.open();
                } else {
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
            let file_path = cmd.cvt_file_url_to_local(videoPlay.video_path);
            let _ss = "";
            let _to = "";

            if (input_start.text != root.need_most_value_char)
                _ss = `-ss ${input_start.text}`;
            if (input_end.text != root.need_most_value_char)
                _to = `-to ${input_end.text}`;

            let copy_audio_codec = "";
            if (cmd.can_copy(in_path, root.get_extension(out_path), "audio"))
                copy_audio_codec = "-c:a copy";

            cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" ${_ss} ${_to} ${copy_audio_codec} "${out_path}"`);
            cmd.exec_ffmpeg();
        }
    }

    Com.MsgDialog {
        id: msg
    }

    Ffmpeg_cmd {
        id: cmd
    }
}
