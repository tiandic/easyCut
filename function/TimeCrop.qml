import QtQuick 2.15
import QtQuick.Layouts 1.15

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property var stackView

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
                onClicked: stackView.pop()
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
                placeholder: "00:10:54"
            }
            Com.LabelInput2 {
                id: input_end
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("结束时间")
                placeholder: "00:15:04"
            }
        }

        Com.Button {
            Layout.fillWidth: true
            text_: qsTr("确认")
            onClicked: {
                let m;
                if ((m = check_input(input_start.text)) != "") {
                    msg.text = qsTr("开始时间格式错误: ") + m;
                    msg.open();
                } else if ((m = check_input(input_end.text)) != "") {
                    msg.text = qsTr("结束时间格式错误: ") + m;
                    msg.open();
                } else if (cvt_time_to_ms(input_start.text) > cvt_time_to_ms(input_end.text)) {
                    msg.text = qsTr("开始时间不能大于结束时间!");
                    msg.open();
                } else if (cvt_time_to_ms(input_start.text) == cvt_time_to_ms(input_end.text)) {
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
            cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" -ss ${input_start.text} -to ${input_end.text} "${out_path}"`);
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
