import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCore
import QtQuick.Dialogs

import "../common" as Com

Item {
    id: root
    property string video_path: ""
    property var stackView

    function cvt_rect_to_input_with_w(num) {
        // console.debug("video_width: ", videoPlay.video_width);
        // console.debug("rect width: ", rect.width);
        // console.debug();

        return Math.round(num * videoPlay.video_width / rect.width);
    }

    function cvt_input_to_rect_with_w(num) {
        // console.debug("video_width: ", videoPlay.video_width);
        // console.debug("rect width: ", rect.width);
        // console.debug();

        return Math.round(num * rect.width / videoPlay.video_width);
    }

    function cvt_rect_to_input_with_h(num) {
        return Math.round(num * videoPlay.video_height / rect.height);
    }

    function cvt_input_to_rect_with_h(num) {
        return Math.round(num * rect.height / videoPlay.video_height);
    }

    ColumnLayout {
        id: input
        // anchors.centerIn: parent
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
                id: input_x
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: "x"
                placeholder: "0"

                // text: rect.rect_X

                onTextChanged: Qt.callLater(function () {
                    if (!input_x.hasFocus)
                        return;
                    if (input_x.text == "")
                        return;
                    console.debug("change rect x:", input_x.text);
                    if (cvt_input_to_rect_with_w(parseInt(input_x.text)) !== rect.rect_X)
                        rect.rect_X = cvt_input_to_rect_with_w(parseInt(input_x.text));
                })
            }
            Com.LabelInput2 {
                id: input_y
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: "y"
                placeholder: "0"

                // text: rect.rect_Y

                onTextChanged: Qt.callLater(function () {
                    if (!input_y.hasFocus)
                        return;
                    if (input_y.text == "")
                        return;
                    console.debug("change rect y:", input_y.text);
                    if (cvt_input_to_rect_with_h(parseInt(input_y.text)) !== rect.rect_Y)
                        rect.rect_Y = cvt_input_to_rect_with_h(parseInt(input_y.text));
                })
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Com.LabelInput2 {
                id: input_w
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("宽")
                placeholder: videoPlay.video_width

                // text: rect.rect_X1 - rect.rect_X

                onTextChanged: Qt.callLater(function () {
                    if (!input_w.hasFocus)
                        return;
                    if (input_w.text == "")
                        return;
                    console.debug("change rect width:", input_w.text);
                    if (cvt_input_to_rect_with_w(parseInt(input_w.text)) !== rect.rect_X1 - rect.rect_X)
                        rect.rect_X1 = cvt_input_to_rect_with_w(rect.rect_X + parseInt(input_w.text));
                })
            }
            Com.LabelInput2 {
                id: input_h
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("高")
                placeholder: videoPlay.video_height

                // text: rect.rect_Y1 - rect.rect_Y

                onTextChanged: Qt.callLater(function () {
                    if (!input_h.hasFocus)
                        return;
                    if (input_w.text == "")
                        return;
                    console.debug("change rect height:", input_h.text);
                    if (cvt_input_to_rect_with_h(parseInt(input_h.text)) !== rect.rect_Y1 - rect.rect_Y)
                        rect.rect_Y1 = cvt_input_to_rect_with_h(rect.rect_Y + parseInt(input_h.text));
                })
            }
        }

        Com.Button {
            Layout.fillWidth: true
            text_: qsTr("确认")
            onClicked: {
                save_path_select.dialog.open();
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

        video_path: video_path
        Com.Myrect {
            id: rect

            function updateRect() {
                var mapped = videoPlay.videooutput.mapToItem(videoPlay, videoPlay.videooutput.contentRect.x, videoPlay.videooutput.contentRect.y, videoPlay.videooutput.contentRect.width, videoPlay.videooutput.contentRect.height);

                console.log("contentRect:", videoPlay.videooutput.contentRect.x, videoPlay.videooutput.contentRect.y, videoPlay.videooutput.contentRect.width, videoPlay.videooutput.contentRect.height);
                console.log("mapped:", mapped.x, mapped.y, mapped.width, mapped.height);

                rect_X = 10;
                rect_Y = 10;
                rect_X1 = mapped.width - 10;
                rect_Y1 = mapped.height - 10;

                x = mapped.x;
                y = mapped.y;
                width = mapped.width;
                height = mapped.height;

                // 初始化输入框的数据
                // input_x.text = rect_X;
                // input_y.text = rect_Y;
                // input_w.text = rect_X1 - rect_X;
                // input_h.text = rect_Y1 - rect_Y;
                input_x.text = cvt_rect_to_input_with_w(rect.rect_X);
                input_y.text = cvt_rect_to_input_with_h(rect.rect_Y);
                input_w.text = cvt_rect_to_input_with_w(rect.rect_X1 - rect.rect_X);
                input_h.text = cvt_rect_to_input_with_h(rect.rect_Y1 - rect.rect_Y);
            }

            Connections {
                target: videoPlay.videooutput
                onContentRectChanged: rect.updateRect()
            }

            // 避免选框超出边界
            onRect_XChanged: {
                if (rect_X < 0)
                    rect_X = 0;
                // if (parseInt(input_x.text) != rect.rect_X)
                // input_x.text = rect_X;
            }
            onRect_YChanged: {
                if (rect_Y < 0)
                    rect_Y = 0;
                // if (parseInt(input_y.text) != rect.rect_Y)
                // input_y.text = rect_Y;
            }
            onRect_X1Changed: {
                if (rect_X1 > width)
                    rect_X1 = width;
                // if (parseInt(input_w.text) != rect.rect_X1 - rect_X)
                // input_w.text = rect_X1 - rect_X;
            }
            onRect_Y1Changed: {
                if (rect_Y1 > height)
                    rect_Y1 = height;
                // if (parseInt(input_h.text) != rect.rect_Y1 - rect_Y)
                // input_h.text = rect_Y1 - rect_Y;
            }
        }
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

    Com.SavePathSelect {
        id: save_path_select
        input_video_path: videoPlay.video_path
        onSelected: function (in_path, out_path) {
            let file_path = cmd.cvt_file_url_to_local(videoPlay.video_path);
            let crop_str = `${input_w.text}:${input_h.text}:${input_x.text}:${input_y.text}`;
            cmd.push_ffmpeg_cmd(`ffmpeg -y -i "${in_path}" -vf "crop=${crop_str}" "${out_path}"`);
            cmd.exec_ffmpeg();
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: true

        onTriggered: {

            // console.debug();
            // console.debug("input: ", input_x.text, input_y.text, input_w.text, input_h.text);
            // console.debug("rect: ", rect.rect_X, rect.rect_Y, rect.rect_X1 - rect.rect_X, rect.rect_Y1 - rect.rect_Y);

            if (!input_x.hasFocus && parseInt(input_x.text) != rect.rect_X && rect.mouse_pressed)
                input_x.text = cvt_rect_to_input_with_w(rect.rect_X);
            if (!input_y.hasFocus && parseInt(input_y.text) != rect.rect_Y && rect.mouse_pressed)
                input_y.text = cvt_rect_to_input_with_h(rect.rect_Y);
            if (!input_w.hasFocus && parseInt(input_w.text) != rect.rect_X1 - rect.rect_X && rect.mouse_pressed)
                input_w.text = cvt_rect_to_input_with_w(rect.rect_X1 - rect.rect_X);
            if (!input_h.hasFocus && parseInt(input_h.text) != rect.rect_Y1 - rect.rect_Y && rect.mouse_pressed)
                input_h.text = cvt_rect_to_input_with_h(rect.rect_Y1 - rect.rect_Y);
        }
    }

    onVideo_pathChanged: videoPlay.video_path = video_path

    Ffmpeg_cmd {
        id: cmd
    }
}
