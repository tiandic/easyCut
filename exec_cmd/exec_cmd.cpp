#include <fstream>
#include <sstream>
#include <string>

#if !defined(_WIN32)
#include <cstdlib>
#endif

int main(int argc, char *argv[]) {
  std::ifstream f(argv[1]);
  std::string line;

  int ret = -1;

  if (std::getline(f, line))
    ret = system(line.c_str());

#if !defined(_WIN32)
  ret = WEXITSTATUS(ret);
#endif

  if (ret == 0) {
    // ffmpeg正常处理完毕后, 删除已经执行了的行
    std::stringstream buf;
    buf << f.rdbuf();
    f.close();

    std::ofstream f2(argv[1]);
    f2 << buf.str();
  }

  return ret;
}
