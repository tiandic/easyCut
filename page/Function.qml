import QtQuick 2.15
import "../common" as Com

Item {
    property string video_path: ""
    Com.VideoPlay{
        id: videoPlay
        anchors.fill: parent
        video_path: video_path
    }
    onVideo_pathChanged: videoPlay.video_path=video_path

}
