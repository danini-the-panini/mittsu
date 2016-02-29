module Mittsu
  class OpenGLState
    def initialize
      @new_attributes = Array.new(16) # Uint8Array
      @enabled_attributes = Array.new(16) # Uint8Array

      @current_blending = nil
      @current_blend_equation = nil
      @current_blend_src = nil
      @current_blend_dst = nil
      @current_blend_equation_alpha = nil
      @current_blend_src_alpha = nil
      @current_blend_dst_alpha = nil

      @current_depth_test = nil
      @current_depth_write = nil

      @current_color_write = nil

      @current_double_sided = nil
      @current_flip_sided = nil

      @current_line_width = nil

      @current_polygon_offset = nil
      @current_polygon_offset_factor = nil
      @current_polygon_offset_units = nil
    end

    def init_attributes
      @new_attributes.length.times do |i|
        @new_attributes[i] = false
      end
    end

    def enable_attribute(attribute)
      glEnableVertexAttribArray(attribute)
      @new_attributes[attribute] = true

      if !@enabled_attributes[attribute]
        # glEnableVertexAttribArray(attribute)
        @enabled_attributes[attribute] = true
      end
    end

    def disable_unused_attributes
      @enabled_attributes.length.times do |i|
        if @enabled_attributes[i] && !@new_attributes[i]
          glDisableVertexAttribArray(i)
          @enabled_attributes[i] = false
        end
      end
    end

    def set_blending(blending, blend_equation = nil, blend_src = nil, blend_dst = nil, blend_equation_alpha = nil, blend_src_alpha = nil, blend_dst_alpha = nil)
      if blending != @current_blending
        case blending
        when NoBlending
          glDisable(GL_BLEND)
        when AdditiveBlending
          glEnable(GL_BLEND)
          glBlendEquation(GL_FUNC_ADD)
          glBlendFunc(GL_SRC_ALPHA, GL_ONE)
        when SubtractiveBlending
          # TODO: Find blendFuncSeparate() combination ???
          glEnable(GL_BLEND)
          glBlendEquation(GL_FUNC_ADD)
          glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_COLOR)
        when MultiplyBlending
          # TODO: Find blendFuncSeparate() combination ???
          glEnable(GL_BLEND)
          glBlendEquation(GL_FUNC_ADD)
          glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_COLOR)
        when CustomBlending
          glEnable(GL_BLEND)
        else
          glEnable(GL_BLEND)
          glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD)
          glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
        end

        @current_blending = blending
      end

      if blending == CustomBlending
        blend_equation_alpha ||= blend_equation
        blend_src_alpha ||= blend_src
        blend_dst_alpha ||= blend_dst

        if blend_equation != @current_blend_equation || blend_equation_alpha != @current_blend_equation_alpha
          glBlendEquationSeparate(GL_MITTSU_PARAMS[blend_equation], GL_MITTSU_PARAMS[blend_equation_alpha])

          @current_blend_equation = blend_equation
          @current_blend_equation_alpha = blend_equation_alpha
        end

        if blend_src != @current_blend_src || blend_dst != @current_blend_dst || blend_src_alpha != @current_blend_src_alpha || blend_dst_alpha != @current_blend_dst_alpha
          glBlendFuncSeparate(GL_MITTSU_PARAMS[blend_src], GL_MITTSU_PARAMS[blend_dst], GL_MITTSU_PARAMS[blend_src_alpha], GL_MITTSU_PARAMS[blend_dst_alpha])

          @current_blend_src = nil
          @current_blend_dst = nil
          @current_blend_src_alpha = nil
          @current_blend_dst_alpha = nil
        end
      else
        @current_blend_equation = nil
        @current_blend_src = nil
        @current_blend_dst = nil
        @current_blend_equation_alpha = nil
        @current_blend_src_alpha = nil
        @current_blend_dst_alpha = nil
      end
    end

    def set_depth_test(depth_test)
      if @current_depth_test != depth_test
        if depth_test
          glEnable(GL_DEPTH_TEST)
        else
          glDisable(GL_DEPTH_TEST)
        end

        @current_depth_test = depth_test
      end
    end

    def set_depth_write(depth_write)
      if @current_depth_write != depth_write
        glDepthMask(depth_write ? GL_TRUE : GL_FALSE)
        @current_depth_write = depth_write
      end
    end

    def set_color_write(color_write)
      if @current_color_write != color_write
        gl_color_write = color_write ? GL_TRUE : GL_FALSE
        glColorMask(gl_color_write, gl_color_write, gl_color_write, gl_color_write)
        @current_color_write = color_write
      end
    end

    def set_double_sided(double_sided)
      if @current_double_sided != double_sided
        if double_sided
          glDisable(GL_CULL_FACE)
        else
          glEnable(GL_CULL_FACE)
        end

        @current_double_sided = double_sided
      end
    end

    def set_flip_sided(flip_sided)
      if @current_flip_sided != flip_sided
        if flip_sided
          glFrontFace(GL_CW)
        else
          glFrontFace(GL_CCW)
        end

        @current_flip_sided = flip_sided
      end
    end

    def set_line_width(width)
      if width != @current_line_width
        glLineWidth(width)
        @current_line_width = width
      end
    end

    def set_polygon_offset(polygon_offset, factor, units)
      if @current_polygon_offset != polygon_offset
        if polygon_offset
          glEnable(GL_POLYGON_OFFSET_FILL)
        else
          glDisable(GL_POLYGON_OFFSET_FILL)
        end

        @current_polygon_offset = polygon_offset
      end

      if polygon_offset && (@current_polygon_offset_factor != factor || @current_polygon_offset_units != units)
        glPolygonOffset(factor, units)

        @current_polygon_offset_factor = factor
        @current_polygon_offset_units = units
      end
    end

    def reset
      @enabled_attributes.length.times do |i|
        @enabled_attributes[i] = false
      end

      @current_blending = nil
      @current_depth_test = nil
      @current_depth_write = nil
      @current_color_write = nil
      @current_double_sided = nil
      @current_flip_sided = nil
    end
  end
end
