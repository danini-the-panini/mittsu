set -x
set -e
if [ ! -e glfw-3.1.2/include/GLFW/glfw3.h ]; then
  wget https://github.com/glfw/glfw/releases/download/3.1.2/glfw-3.1.2.zip
  unzip glfw-3.1.2.zip;
fi
if [ ! -e glfw3-3.1.2/src/libglfw3.a ]; then
  cd glfw-3.1.2
  cmake .
  make && sudo make install;
fi
