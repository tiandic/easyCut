#include <fstream>
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

  return ret;
}
