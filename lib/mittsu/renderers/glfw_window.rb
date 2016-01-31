require 'opengl'
require 'glfw'

path = `pkg-config glfw3 --libs-only-L`.chomp.strip[2..-1]
GLFW.load_lib('libglfw3.dylib', path)

include GLFW

module Mittsu
  module GLFW
    class Window
      attr_accessor :key_press_handler, :key_release_handler, :key_repeat_handler, :char_input_handler

      def initialize(width, height, title)
        glfwInit

        glfwWindowHint GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE
        glfwWindowHint GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE
        glfwWindowHint GLFW_CONTEXT_VERSION_MAJOR, 3
        glfwWindowHint GLFW_CONTEXT_VERSION_MINOR, 3
        glfwWindowHint GLFW_CONTEXT_REVISION, 0

        @width, @height, @title = width, height, title
        @handle = glfwCreateWindow(@width, @height, @title, nil, nil)
        glfwMakeContextCurrent @handle
        glfwSwapInterval 1

        this = self
        @key_callback = ::GLFW::create_callback(:GLFWkeyfun) do |window_handle, key, scancode, action, mods|
          if action == GLFW_PRESS
            this.key_press_handler.call(key) unless this.key_press_handler.nil?
            this.key_repeat_handler.call(key) unless this.key_repeat_handler.nil?
          elsif action == GLFW_RELEASE
            this.key_release_handler.call(key) unless this.key_release_handler.nil?
          elsif action == GLFW_REPEAT
            this.key_repeat_handler.call(key) unless this.key_repeat_handler.nil?
          end
        end
        glfwSetKeyCallback(@handle, @key_callback)

        @char_callback = ::GLFW::create_callback(:GLFWcharfun) do |window_handle, codepoint|
          char = [codepoint].pack('U')
          this.char_input_handler.call(char) unless this.char_input_handler.nil?
        end
        glfwSetCharCallback(@handle, @char_callback)
      end

      def run
        while glfwWindowShouldClose(@handle) == 0
          yield

          glfwSwapBuffers @handle
          glfwPollEvents
        end
        glfwDestroyWindow @handle
        glfwTerminate
      end

      def framebuffer_size
        width, height = ' '*8, ' '*8
        glfwGetFramebufferSize(@handle, width, height)
        [width.unpack('L')[0], height.unpack('L')[0]]
      end

      def on_key_pressed &block
        @key_press_handler = block
      end

      def on_key_released &block
        @key_release_handler = block
      end

      def on_key_typed &block
        @key_repeat_handler = block
      end

      def key_down?(key)
        glfwGetKey(@handle, key) == GLFW_PRESS
      end

      def on_character_input &block
        @char_input_handler = block
      end
    end
  end
end
