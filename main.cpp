#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <qfont.h>
#include <qlist.h>

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  QString font_path = ":/fonts/Noto_Sans_Mono_CJK_SC.ttf";
  int font_id = QFontDatabase::addApplicationFont(font_path);
  if (font_id == -1) {
    qWarning() << "font" << font_path << "load fail!";
  } else {
    QList<QString> families = QFontDatabase::applicationFontFamilies(font_id);
    if (!families.isEmpty()) {
      QFont font(families.at(0));
      font.setPixelSize(12);
      app.setFont(font);
    }
  }

  QQmlApplicationEngine engine;
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("easyCut", "Main");

  return QCoreApplication::exec();
}
