# easyCut
这是一个为简单视频处理而生的工具

## 优点:
- 设计简单, 易于添加新功能
- 界面简洁易用, 以引导式的交互让每个页面都只有两到三个输入框与按钮, 几乎没有学习成本
- 占用资源极低, 能够在有限的机器上运行
- 使用`ffmpeg`命令进行最终视频处理, 可跨平台, 跨机器进行最终处理输出

## 缺点(与其他剪辑工具相比):
- 缺乏`人声增强`,`去除环境噪音`,`音乐裁剪`等音频处理功能
- 缺乏`淡入淡出`,`闪白`,`模糊`等特效功能
- 缺乏`冻结画面`,`变速`等功能

## 目前已有功能:
- `画面裁剪`
- `视频拼接`
- `提取音频`
- `添加音频`
- `添加字幕`
- `按时间裁剪`
- `提取所有帧`

如有其他希望添加的功能, 请在`issues`中提出
## build
依赖:
- `qt6-declarative`
- `qt6-multimedia`
- `libavformat`
- `libavcodec`
- `libswscale`
- `libavutil`
- `libswresample`
- `libavfilter`

### Linux
```
# arch
sudo pacman --needed -S base-devel cmake qt6-declarative qt6-multimedia ffmpeg
```

```
mkdir build && cd build
cmake ..
make -j$(nproc)
make install
```

### Windows

```
# msys2 mingw
pacman -S mingw-w64-x86_64-toolchain mingw-w64-x86_64-cmake mingw-w64-x86_64-qt6-declarative mingw-w64-x86_64-qt6-multimedia mingw-w64-x86_64-ffmpeg
```

```
cmake -B build -G Ninja
cmake --build build
```
