set -x
set -e

glfwversion=3.3.1

if [ ! -e glfw-3.3.1/include/GLFW/glfw3.h ]; then
  wget https://github.com/glfw/glfw/releases/download/$glfwversion/glfw-$glfwversion.zip
  unzip glfw-$glfwversion.zip;
fi
cd glfw-$glfwversion
if [ ! -e src/libglfw3.so ]; then
  cmake -D BUILD_SHARED_LIBS=ON .
  make;
fi
if [ ! -e /usr/local/lib/libglfw.so ]; then
  sudo make install;
fi
