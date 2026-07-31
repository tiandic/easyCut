# easyCut
这是一个为简单视频处理而生的工具

## 优点:
- 设计简单, 易于添加新功能
- 界面简洁易用, 以引导式的交互让每个页面都只有两到三个输入框与按钮, 几乎没有学习成本
- 占用资源极低, 能够在资源有限的机器上运行
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

## 功能页面预览及说明:
- [1.画面裁剪](./1.画面裁剪)
- [2.视频裁剪](./2.视频裁剪)
- [3.视频拼接](./3.视频拼接)
- [4.提取音频](./4.提取音频)
- [5.添加音频](./5.添加音频)
- [6.添加字幕](./6.添加字幕)
- [7.提取所有帧](./7.提取所有帧)
- [最值](./901.最值)

## 安装:
### 1. 从 AUR 安装
```
yay -S easyCut
```

### 2. 从 [releases](https://github.com/tiandic/easyCut/releases) 安装
#### 2.1 Linux
安装依赖
```
# arch
sudo pacman -S --needed qt6-declarative qt6-multimedia ffmpeg
```
对应文件为`easyCut-<version>-linux-amd64.*`

解压后,其中的 `bin/appeasyCut` 即软件本体

#### 2.2 Windows
在 [releases](https://github.com/tiandic/easyCut/releases) 下载对应文件

如果你的系统安装了 `ffmpeg` 并且添加到了`PATH`, 那么可以选择 `easyCut-<version>-windows-amd64.*`

如果没有, 那么就需要下载 `easyCut-<version>-with-ffmpeg-windows-amd64.*`

解压后,其中的 `bin/appeasyCut.exe` 即软件本体

### 3. 从构建安装
依赖:
- `qt6-declarative`
- `qt6-multimedia`
- `libavformat`
- `libavcodec`
- `libswscale`
- `libavutil`
- `libswresample`
- `libavfilter`

#### 3.1 Linux
```
# arch
sudo pacman -S --needed base-devel cmake qt6-declarative qt6-multimedia ffmpeg
```

```
mkdir build && cd build
cmake ..
make -j$(nproc)

./appeasyCut
# or
make install
```

#### 3.2 Windows
使用 msys2 mingw64 构建
```
pacman -S --needed --noconfirm mingw-w64-x86_64-toolchain
pacman -S --needed --noconfirm mingw-w64-x86_64-cmake
pacman -S --needed --noconfirm mingw-w64-x86_64-qt6-declarative
pacman -S --needed --noconfirm mingw-w64-x86_64-qt6-multimedia
pacman -S --needed --noconfirm mingw-w64-x86_64-ffmpeg
```

```
# 输出到桌面
cmake -B build "-DCMAKE_INSTALL_PREFIX=/c/Users/${USER}/Desktop/easyCut"
cmake --build build

cmake --install build

# 复制msys2环境的依赖到 easyCut 所在目录中
cd "/c/Users/${USER}/Desktop/easyCut/bin"
ldd ./appeasyCut.exe | grep '/mingw64/' | awk '{print $3}' | xargs -I{} cp -n {} .

# 运行
./appeasyCut.exe
```

## 关于 Windows
软件在`Windows`下的体验相比于`Linux`较差

针对`Windows`的优化已在计划中

## 特殊功能说明
需要特别提到的功能是 [最值](https://github.com/tiandic/easyCut/wiki/901.%E6%9C%80%E5%80%BC)

当`按时间裁剪`视频时,有没有从特定时间开始,一直到视频末尾的需求?

如果有, 那么只需要在`开始时间`的输入框中填写这个特定时间, 然后在`结束输入框`中填写`-`即可, 无须手动填写视频末尾时间, 软件处理好一切

处理`按时间裁剪`功能外, 其他视频处理功能也有 `最值` 选项,详细见 [最值 - wiki](https://github.com/tiandic/easyCut/wiki/901.%E6%9C%80%E5%80%BC)

<img width="1918" height="1042" alt="Screenshot from 2026-07-28 13-09-17" src="https://github.com/user-attachments/assets/33e1c061-7f9c-465c-82b2-c0b1c13f5aab" />
