import QtQuick 2.15
import QtMultimedia

Item {
    property string video_path: ""

    onVideo_pathChanged: videoProvider.videoPath=video_path

    VideoProvider {
        id: videoProvider
        videoPath: video_path
        videoSink: videoOutput.videoSink
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
        onClicked: videoProvider.videoPlaying ? videoProvider.stop() : videoProvider.start()
    }

}
