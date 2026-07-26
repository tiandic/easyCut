这个软件用于运行程序,并通过绘制一个窗口实现跨平台地查看命令行程序输出

在本项目中,它被用于启动`exec_cmd`程序

它可以这样使用:
```
./appexec_cmd_gui "" ls -la ..
./appexec_cmd_gui "/tmp/a.txt" ls -la .. # 在这里, "/tmp/a.txt" 会在 "ls -la .." 命令结束后被删除
```
它会被`easyCut`这样调用:
```
./appexec_cmd_gui "" ./exec_cmd ~/.local/share/appeasyCut/ffmpeg_cmd_list.txt
# or
./appexec_cmd_gui "~/.local/share/appeasyCut/1785038523681_subtitles.srt" ./exec_cmd ~/.local/share/appeasyCut/ffmpeg_cmd_list.txt
```
