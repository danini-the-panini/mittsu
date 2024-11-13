require 'mittsu/renderers/glfw_window'

module Mittsu
  module GLFW
    class Window
      attr_accessor :key_press_handler, :key_release_handler, :key_repeat_handler, :char_input_handler, :cursor_pos_handler, :mouse_button_press_handler, :mouse_button_release_handler, :scroll_handler, :framebuffer_size_handler

      def initialize(width, height, title, antialias: 0)
        @width, @height, @title, @antialias = width, height, title, antialias
      end

      def run
        10.times do |i|
          yield
        end
      end

      def framebuffer_size
        [@width, @height]
      end

      def on_key_pressed &block
      end

      def on_key_released &block
      end

      def on_key_typed &block
      end

      def key_down?(key)
        false
      end

      def on_character_input &block
      end

      def on_mouse_move &block
      end

      def on_mouse_button_pressed &block
      end

      def on_mouse_button_released &block
      end

      def mouse_position
        Vector2.new(0.0, 0.0)
      end

      def mouse_button_down?(button)
        false
      end

      def on_scroll &block
      end

      def on_resize &block
      end

      def joystick_buttons(joystick = nil)
        []
      end

      def joystick_axes(joystick = nil)
        []
      end

      def on_joystick_button_pressed &block
      end

      def on_joystick_button_released &block
      end

      def joystick_present?(joystick = nil)
        false
      end

      def joystick_button_down?(button, joystick = nil)
        false
      end

      def joystick_name(joystick = nil)
        'FAKE JOYSTICK'
      end
    end
  end
end
