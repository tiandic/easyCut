import QtQuick 2.15
import QtQuick.Controls 2
import QtQuick.Layouts
import QtMultimedia

import "../common" as Com

Item {
    property string video_path: ""
    onVideo_pathChanged: videoProvider.videoPath = video_path
    property var last_ms: Date.now()

    property var videooutput: videoOutput
    property var video_provider: videoProvider
    property int video_width: videoProvider.videoWidth
    property int video_height: videoProvider.videoHeight

    property string playing_icon: "▶"
    property string pausing_icon: "⏸"

    property bool need_toggle_play_status: false // 当被设置为 true 时,会触发播放状态切换

    function toggle_play_status() {
        if (videoProvider.videoPlaying) {
            videoProvider.stop();
            play_button.text_ = playing_icon;
        } else {
            videoProvider.start();
            play_button.text_ = pausing_icon;
        }
    }

    onNeed_toggle_play_statusChanged: {
        if (need_toggle_play_status) {
            need_toggle_play_status = false;
            toggle_play_status();
        }
    }

    Item {
        id: screen

        anchors {
            top: parent.top
            bottom: control.top
            left: parent.left
            right: parent.right
        }

        VideoProvider {
            id: videoProvider
            videoPath: video_path
            videoSink: videoOutput.videoSink
            onVideoPathChanged: {
                if (videoProvider.videoPath != "") {
                    console.log("init video");
                    videoProvider.init_and_show();
                    slider.to = videoProvider.get_total_time() / 100;
                }
            }
        }

        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            onContentRectChanged: {
                console.log(qsTr("视频画面位置:"), contentRect.x, contentRect.y);
                console.log(qsTr("视频画面尺寸:"), contentRect.width, contentRect.height);
            }
            MouseArea {
                x: parent.contentRect.x
                y: parent.contentRect.y
                width: parent.contentRect.width
                height: parent.contentRect.height
                onClicked: {
                    toggle_play_status();
                }
            }
        }

        AudioOutput {
            id: audioOutput
        }
    }

    // 进度条与暂停键等
    ColumnLayout {
        id: control
        anchors {
            // 位于画面下面,并有一定间隔
            bottom: parent.bottom
            left: parent.left
            right: parent.right

            // topMargin: 30
        }

        height: parent.height / 8
        Slider {
            id: slider
            Layout.fillWidth: true
            to: 0

            property bool is_from_videoProvider: false

            onValueChanged: {
                // 同步视频与进度条进度
                if (is_from_videoProvider)
                    return;

                // TODO: 优化拖动时的反馈
                // 避免拖动进度条时卡死
                if (Date.now() - last_ms < 500) {
                    last_ms = Date.now();
                    return;
                }

                // 更改播放进度
                console.log(`slider new value: ${slider.value}`);
                let tmp_play_status = videoProvider.videoPlaying;
                videoProvider.stop();
                videoProvider.seek(slider.value * 100);
                if (tmp_play_status)
                    videoProvider.start();
                else
                    videoProvider.show_a_frame();
            }

            handle: Rectangle {
                x: slider.visualPosition * slider.width// - width / 2 + slider.leftPadding
                y: (parent.height - height) / 2

                width: 14
                height: 14
                radius: 7
                color: "white"
                border.color: "#378ADD"
                border.width: 2
            }

            HoverHandler {
                id: hoverHandler
            }
            PointHandler {
                id: pointHandler
            }

            Rectangle {
                id: tooltip
                visible: hoverHandler.hovered || slider.pressed
                x: {
                    let pos_x = slider.pressed ? pointHandler.point.position.x - width / 2 : hoverHandler.point.position.x - width / 2;
                    if (pos_x + (width / 2 + 3) > slider.width)
                        return slider.width - width - 3;
                    if (pos_x <= 0)
                        return 3;
                    else
                        return pos_x;
                }
                y: (slider.pressed ? pointHandler.point.position.y - height - 10 : hoverHandler.point.position.y - height - 10)
                width: 68
                height: 26
                radius: 6
                color: "#1e1e1e"

                Label {
                    id: tooltipLabel
                    anchors.centerIn: parent
                    font.pixelSize: 12
                    color: "white"

                    text: {
                        let ratio;

                        if (slider.pressed)
                            ratio = slider.value / slider.to;
                        else
                            ratio = hoverHandler.point.position.x / slider.availableWidth;

                        let TotalSec = Math.round(ratio * slider.to);
                        let m = Math.floor(TotalSec / 60);
                        let s = Math.floor(TotalSec % 60);

                        return `${m}:${String(s).padStart(2, "0")}`;
                    }
                }
            }
        }

        RowLayout {
            spacing: 10
            Com.Button {
                id: play_button
                Layout.preferredWidth: 40
                Layout.preferredHeight: Layout.preferredWidth
                radius: Layout.preferredHeight / 2

                text_: "▶"
                onClicked: {
                    toggle_play_status();
                }
            }

            Com.LabelInput2 {
                id: input_progress
                label: qsTr("进度")
                Layout.preferredWidth: 95
                text: ""
                onSubmitted: {
                    let m_and_s = text.split(":");
                    let TotalSec = parseInt(m_and_s[0]) * 60 + parseInt(m_and_s[1]);
                    slider.value = TotalSec;
                }
            }
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: true

        onTriggered: {
            if (!input_progress.hasFocus) {
                let TotalSec = slider.value;
                let m = Math.floor(TotalSec / 60);
                let s = Math.floor(TotalSec % 60);

                input_progress.text = `${m}:${String(s).padStart(2, "0")}`;
            }

            slider.is_from_videoProvider = true;
            slider.value = videoProvider.progressTime / 100;
            slider.is_from_videoProvider = false;
        }
    }
}
