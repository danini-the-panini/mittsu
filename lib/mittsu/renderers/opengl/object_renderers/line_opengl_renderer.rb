module Mittsu
  class LineOpenGLRenderer
    def initialize(line, renderer)
      @line = line
      @renderer = renderer
    end

    def render_buffer(camera, lights, fog, material, geometry_group, update_buffers)
      mode = @line.mode == LineStrip ? GL_LINE_STRIP : GL_LINES

      @renderer.state.set_line_width(material.line_width * @renderer.pixel_ratio)

      glDrawArrays(mode, 0, geometry_group.line_count)

      @renderer.info[:render][:calls] += 1
    end
  end
end
