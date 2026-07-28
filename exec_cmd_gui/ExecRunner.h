#ifndef EXEC_RUNNER_H
#define EXEC_RUNNER_H

#include "QtNetwork/qlocalsocket.h"
#include "qcoreapplication.h"
#include <QObject>
#include <QProcess>
#include <QtCore>
#include <QtQml>

class ExecRunner : public QObject {
  Q_OBJECT
  QML_ELEMENT
  Q_PROPERTY(QString output READ output NOTIFY outputChanged)

public:
  explicit ExecRunner(QObject *parent = nullptr) : QObject(parent) {
    connect(&process, &QProcess::readyReadStandardOutput, this,
            [this] { append_output(process.readAllStandardOutput()); });
    connect(&process, &QProcess::readyReadStandardError, this,
            [this] { append_output(process.readAllStandardError()); });
    connect(&process,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this](int exit_code) {
              if (exit_code == 0) {
                start_rm_file();
                qApp->quit();
              }
            });
    // 向 ffmpeg 所在进程输入 'q' 才能终止ffmpeg的运行
    // 无论是调用 kill() 还是 terminate()都无法终止
    connect(QCoreApplication::instance(), &QCoreApplication::aboutToQuit, this,
            [this]() { process.write("q"); });
  }

  Q_INVOKABLE void run(QString exec_path, QList<QString> argv) {
    process.start(exec_path, argv);
  }

  Q_INVOKABLE void set_rm_file_path(QString path) { rm_file_path = path; }

  QString output() { return m_output; }

signals:
  void outputChanged();

private:
  QString m_output;
  QProcess process;
  QString rm_file_path = "";

  void start_rm_file() {
    if (rm_file_path == "")
      return;
    QFile::remove(rm_file_path);
  }

  void append_output(QByteArray o) {
    m_output += QString::fromLocal8Bit(o);
    int idx;
    int idx2;
    while ((idx = m_output.indexOf('\r')) != -1) {
      if ((idx2 = m_output.lastIndexOf('\n', idx)) == -1)
        break;

      // ffmpeg 是行输出后面跟'\r' ,而非'\r'后面跟行输出
      // 所以`\r`必然在行末, 如果出现'\r'就立即删除会导致`进度行`不显示
      if (m_output.last(1) == '\r' && m_output.count('\r') < 2)
        break;

      m_output =
          m_output.left(idx2 + 1) + m_output.right(m_output.length() - idx - 1);
    }
    emit outputChanged();
  }
};

#endif // EXEC_RUNNER_H
