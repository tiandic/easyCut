import QtQuick 2.15
import QtQuick.Controls 2
import QtMultimedia

Item {

    property string video_path: ""
    onVideo_pathChanged: videoProvider.videoPath = video_path

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
            onVideoPathChanged : {
                if (videoProvider.videoPath!=""){
                    videoProvider.init_and_show();
                    slider.to = videoProvider.get_total_time()/100;
                }

            }
        }

        VideoOutput {
            id: videoOutput
            anchors.fill: parent
        }

        AudioOutput {
            id: audioOutput
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                videoProvider.videoPlaying ? videoProvider.stop() : videoProvider.start()
            }
        }
    }

    Item {
        id: control
        // 进度条与暂停键等

        anchors {
            // 位于画面下面,并有一定间隔
            bottom: parent.bottom
            left: parent.left
            right: parent.right

            // topMargin: 30
        }

        height: parent.height / 6
        Slider {
            id: slider
            anchors {
                left: parent.left
                right: parent.right
            }
            to: 0

            onValueChanged: {
                // 更改播放进度
                console.log(`slider new value: ${slider.value}`)
                let tmp_play_status=videoProvider.videoPlaying
                videoProvider.stop()
                videoProvider.seek(slider.value*100)
                if (tmp_play_status)
                    videoProvider.start()
                videoProvider.show_a_frame()
            }

            handle: Rectangle {
                x: parent.visualPosition * parent.width - width / 2 + parent.leftPadding
                // y: (parent.height - height) / 2 + parent.topPadding

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
    }
}
