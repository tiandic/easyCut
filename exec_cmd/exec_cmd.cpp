#include <fstream>
#include <string>

int main(int argc, char *argv[]) {
  std::ifstream f(argv[1]);
  std::string line;

  if (std::getline(f, line))
    system(line.c_str());

  return 0;
}
