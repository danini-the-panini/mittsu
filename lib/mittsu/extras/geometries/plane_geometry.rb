require 'mittsu/extras/geometries/plane_buffer_geometry'

module Mittsu
  class PlaneGeometry < Geometry
    def initialize(width, height, width_segments = 1, height_segments = 1)
      puts 'Mittsu::PlaneGeometry: Consider using Mittsu::PlaneBufferGeometry for lower memory footprint.'

      super()

      @type = 'PlaneGeometry'

      @parameters = {
        width:           width,
        height:          height,
        width_segments:  width_segments,
        height_segments: height_segments
      };

      from_buffer_geometry(PlaneBufferGeometry.new(width, height, width_segments, height_segments))
    end
  end
end