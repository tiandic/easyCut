import QtQuick 2.0

// 一个可使用鼠标拖动,改变大小的矩形
Item {
    id: myrect

    //矩形的左上角与右下角坐标
    property int rect_X: 0
    property int rect_Y: 0
    property int rect_X1: 100
    property int rect_Y1: 100

    property int rectlinewidth: 5
    property var clr: null

    property bool mouse_enter: false
    property bool mouse_pressed: false

    onRect_XChanged: {
        if (rect_X + 10 > rect_X1)
            rect_X = rect_X1 - 10;
        myrect_root.requestPaint();
    }
    onRect_YChanged: {
        if (rect_Y + 10 > rect_Y1)
            rect_Y = rect_Y1 - 10;
        myrect_root.requestPaint();
    }
    onRect_X1Changed: {
        if (rect_X + 10 > rect_X1)
            rect_X1 = rect_X + 10;
        myrect_root.requestPaint();
    }
    onRect_Y1Changed: {
        if (rect_Y + 10 > rect_Y1)
            rect_Y1 = rect_Y + 10;
        myrect_root.requestPaint();
    }

    Canvas {
        id: myrect_root

        width: parent.width
        height: parent.height
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, myrect_root.width, myrect_root.height);
            ctx.beginPath();
            ctx.lineWidth = rectlinewidth;
            if (clr == null)
                ctx.strokeStyle = "green";
            else
                ctx.strokeStyle = clr;
            ctx.rect(rect_X, rect_Y, (rect_X1 - rect_X), (rect_Y1 - rect_Y));
            ctx.stroke();
        }
    }
    MouseArea {
        // 是否按下了矩形的某条边
        property bool down: false
        property bool down2: false
        property bool down3: false
        property bool down4: false
        // 在中间按下
        property bool down5: false

        // 记录在中间按下后,鼠标与矩形两个坐标的差值,以移动矩形
        property int x_eren: 0
        property int y_eren: 0
        property int x_eren2: 0
        property int y_eren2: 0

        hoverEnabled: true
        anchors.fill: parent

        onPositionChanged: {
            if (!pressed)
                return;
            let devi = 4;
            myrect.mouse_pressed = true;

            // 中间
            if ((!down && !down2 && !down3 && !down4) && ((down5) || (mouseX > rect_X && mouseX < rect_X1 && mouseY > rect_Y && mouseY < rect_Y1))) {
                console.log("中");
                down5 = true;
                if (x_eren == 0 && y_eren == 0 && x_eren2 == 0 && y_eren2 == 0) {
                    // 刚刚按下时,记录在中间按下后鼠标与矩形两个坐标的差值,以移动矩形
                    x_eren = mouseX - rect_X;
                    y_eren = mouseY - rect_Y;
                    x_eren2 = rect_X1 - mouseX;
                    y_eren2 = rect_Y1 - mouseY;
                }

                rect_X = mouseX - x_eren;
                rect_Y = mouseY - y_eren;
                rect_X1 = mouseX + x_eren2;
                rect_Y1 = mouseY + y_eren2;

                console.log("rect_X:", rect_X, "\nrect_Y:", rect_Y, "");
            } else
            // 左边
            if ((down) || (Math.abs(mouseX - rect_X) < devi && mouseY > rect_Y && mouseY < rect_Y1)) {
                console.log("左");
                down = true;
                rect_X = mouseX;
            } else
            // 上边
            if ((down2) || (Math.abs(mouseY - rect_Y) < devi && mouseX > rect_X && mouseX < rect_X1)) {
                console.log("上");
                down2 = true;
                rect_Y = mouseY;
            } else
            // 右边
            if ((down3) || (Math.abs(mouseX - rect_X1) < devi && mouseY > rect_Y && mouseY < rect_Y1)) {
                console.log("右");
                down3 = true;
                rect_X1 = mouseX;
            } else
            // 下边
            if ((down4) || (Math.abs(mouseY - rect_Y1) < devi && mouseX > rect_X && mouseX < rect_X1)) {
                console.log("下");
                down4 = true;
                rect_Y1 = mouseY;
            }
        }

        onReleased: {
            down = false;
            down2 = false;
            down3 = false;
            down4 = false;
            down5 = false;

            x_eren = 0;
            y_eren = 0;
            x_eren2 = 0;
            y_eren2 = 0;

            myrect.mouse_pressed = false;
        }

        onEntered: myrect.mouse_enter = true
        onExited: myrect.mouse_enter = false
    }
}
