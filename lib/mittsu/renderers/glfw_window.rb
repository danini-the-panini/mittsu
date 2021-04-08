require 'opengl'
require 'glfw'

require 'mittsu/utils'
require 'mittsu/renderers/glfw_lib'
glfw_lib = Mittsu::GLFWLib.discover
# Workaround until https://github.com/vaiorabbit/ruby-opengl/pull/32 gets merged
GLFW.class_variable_get('@@lib_signature').each do |sig|
  sig.gsub!(/const void(?!\s*\*)/, 'void')
end
GLFW.load_lib(ENV["MITTSU_LIBGLFW_FILE"] || glfw_lib.file, ENV["MITTSU_LIBGLFW_PATH"] || glfw_lib.path) unless Mittsu.test?

include GLFW

module Mittsu
  module GLFW
    class Window
      attr_accessor :key_press_handler, :key_release_handler, :key_repeat_handler, :char_input_handler, :cursor_pos_handler, :mouse_button_press_handler, :mouse_button_release_handler, :scroll_handler, :framebuffer_size_handler

      def initialize(width, height, title, antialias: 0)
        glfwInit

        glfwWindowHint GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE
        glfwWindowHint GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE
        glfwWindowHint GLFW_CONTEXT_VERSION_MAJOR, 3
        glfwWindowHint GLFW_CONTEXT_VERSION_MINOR, 3
        glfwWindowHint GLFW_CONTEXT_REVISION, 0

        if antialias > 0
          glfwWindowHint GLFW_SAMPLES, antialias
        end

        @width, @height, @title = width, height, title
        @handle = glfwCreateWindow(@width, @height, @title, nil, nil)
        if @handle.null?
          raise "Unable to create window."
        end
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
        glfwSetKeyCallback(@handle, Fiddle::Pointer[@key_callback.to_i])

        @char_callback = ::GLFW::create_callback(:GLFWcharfun) do |window_handle, codepoint|
          char = [codepoint].pack('U')
          this.char_input_handler.call(char) unless this.char_input_handler.nil?
        end
        glfwSetCharCallback(@handle, Fiddle::Pointer[@char_callback.to_i])

        @cursor_pos_callback = ::GLFW::create_callback(:GLFWcursorposfun) do |window_handle, xpos, ypos|
          this.cursor_pos_handler.call(Vector2.new(xpos, ypos)) unless this.cursor_pos_handler.nil?
        end
        glfwSetCursorPosCallback(@handle, Fiddle::Pointer[@cursor_pos_callback.to_i])

        @mouse_button_callback = ::GLFW::create_callback(:GLFWmousebuttonfun) do |window_handle, button, action, mods|
          mpos = this.mouse_position
          if action == GLFW_PRESS
            this.mouse_button_press_handler.call(button, mpos) unless this.mouse_button_press_handler.nil?
          elsif action == GLFW_RELEASE
            this.mouse_button_release_handler.call(button, mpos) unless this.mouse_button_release_handler.nil?
          end
        end
        glfwSetMouseButtonCallback(@handle, Fiddle::Pointer[@mouse_button_callback.to_i])

        @scroll_callback = ::GLFW::create_callback(:GLFWscrollfun) do |window_handle, xoffset, yoffset|
          this.scroll_handler.call(Vector2.new(xoffset, yoffset)) unless this.scroll_handler.nil?
        end
        glfwSetScrollCallback(@handle, Fiddle::Pointer[@scroll_callback.to_i])

        @frabuffer_size_callback = ::GLFW::create_callback(:GLFWframebuffersizefun) do |window_handle, new_width, new_height|
          this.framebuffer_size_handler.call(new_width, new_height) unless this.framebuffer_size_handler.nil?
        end
        glfwSetFramebufferSizeCallback(@handle, Fiddle::Pointer[@frabuffer_size_callback.to_i])

        @joystick_buttons = poll_all_joysticks_buttons
      end

      def run
        while glfwWindowShouldClose(@handle) == 0
          yield

          glfwSwapBuffers @handle
          glfwPollEvents
          poll_joystick_events
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

      def on_mouse_move &block
        @cursor_pos_handler = block
      end

      def on_mouse_button_pressed &block
        @mouse_button_press_handler = block
      end

      def on_mouse_button_released &block
        @mouse_button_release_handler = block
      end

      def mouse_position
        xpos, ypos = ' '*8, ' '*8
        glfwGetCursorPos(@handle, xpos, ypos);
        Vector2.new(xpos.unpack('D')[0], ypos.unpack('D')[0])
      end

      def mouse_button_down?(button)
        glfwGetMouseButton(@handle, button) == GLFW_PRESS
      end

      def on_scroll &block
        @scroll_handler = block
      end

      def on_resize &block
        @framebuffer_size_handler = block
      end

      def joystick_buttons(joystick = GLFW_JOYSTICK_1)
        @joystick_buttons = poll_all_joysticks_buttons
        @joystick_buttons[joystick]
      end

      def joystick_axes(joystick = GLFW_JOYSTICK_1)
        return [] unless joystick_present?(joystick)
        count = ' ' * 4
        array = glfwGetJoystickAxes(joystick, count)
        count = count.unpack('l')[0]
        array[0, count * 4].unpack('f' * count)
      end

      def on_joystick_button_pressed &block
        @joystick_button_press_handler = block
      end

      def on_joystick_button_released &block
        @joystick_button_release_handler = block
      end

      def joystick_present?(joystick = GLFW_JOYSTICK_1)
        glfwJoystickPresent(joystick).nonzero?
      end

      def joystick_button_down?(button, joystick = GLFW_JOYSTICK_1)
        @joystick_buttons[joystick][button]
      end

      def joystick_name(joystick = GLFW_JOYSTICK_1)
        glfwGetJoystickName(joystick)
      end

      def set_mouselock(value)
        if value
          glfwSetInputMode(@handle, GLFW_CURSOR, GLFW_CURSOR_DISABLED)
        else
          glfwSetInputMode(@handle, GLFW_CURSOR, GLFW_CURSOR_NORMAL)
        end
      end

      private

      def poll_all_joysticks_buttons
        (GLFW_JOYSTICK_1..GLFW_JOYSTICK_LAST).map do |joystick|
          poll_joystick_buttons(joystick)
        end
      end

      def poll_joystick_buttons(joystick)
        return nil unless joystick_present?(joystick)
        count = ' ' * 4
        array = glfwGetJoystickButtons(joystick, count)
        count = count.unpack('l')[0]
        array[0, count].unpack('c' * count).map(&:nonzero?)
      end

      def poll_joystick_events
        new_joystick_buttons = poll_all_joysticks_buttons
        new_joystick_buttons.each_with_index do |buttons, joystick|
          poll_single_joystick_events(joystick, buttons)
        end
        @joystick_buttons = new_joystick_buttons
      end

      def poll_single_joystick_events(joystick, buttons)
        return if buttons.nil?
        buttons.each_with_index do |pressed, button|
          fire_joystick_button_event(joystick, button, pressed)
        end
      end

      def fire_joystick_button_event(joystick, button, pressed)
        if !@joystick_buttons[joystick][button] && pressed
          @joystick_button_press_handler.call(joystick, button) unless @joystick_button_press_handler.nil?
        elsif @joystick_buttons[joystick][button] && !pressed
          @joystick_button_release_handler.call(joystick, button) unless @joystick_button_release_handler.nil?
        end
      end
    end
  end
end
