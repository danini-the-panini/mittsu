set -x
set -e
if [ ! -e glfw3-3.1.2/src/libglfw3.a ]; then
  wget https://github.com/glfw/glfw/releases/download/3.1.2/glfw-3.1.2.zip
  unzip glfw-3.1.2.zip
  cmake .
  make && sudo make install;
fi
