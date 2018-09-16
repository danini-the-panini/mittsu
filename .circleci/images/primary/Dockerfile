FROM circleci/ruby:2.5.1

RUN sudo apt-get update; sudo apt-get install cmake xorg-dev libgl1-mesa-dev

RUN wget https://github.com/glfw/glfw/releases/download/3.1.2/glfw-3.1.2.zip -O /tmp/glfw.zip
RUN unzip /tmp/glfw.zip -d /tmp
WORKDIR /tmp/glfw-3.1.2/
RUN cmake -D BUILD_SHARED_LIBS=ON .
RUN make
RUN sudo make install