require 'mittsu/extras/geometries/parametric_buffer_geometry'

module Mittsu
  class ParametricGeometry < Geometry
    def initialize(func, slices, stacks)
      super()

      @type = 'ParametricGeometry'

      @parameters = {
        func:   func,
        slices: slices,
        stacks: stacks
      }

      from_buffer_geometry(ParametricBufferGeometry.new(func, slices, stacks))
      merge_vertices
    end

    def self.klein
      -> (v, u, target = Vector3.new) {
        u *= Math::PI
        v *= 2.0 * Math::PI

        u = u * 2.0
        x = nil
        y = nil
        z = nil

        if u < Math::PI
          x = 3.0 * Math.cos(u) * (1.0 + Math.sin(u)) + (2.0 * (1.0 - Math.cos(u) / 2.0)) * Math.cos(u) * Math.cos(v)
          z = -8.0 * Math.sin(u) - 2.0 * (1.0 - Math.cos(u) / 2.0) * Math.sin(u) * Math.cos(v)
        else
          x = 3.0 * Math.cos(u) * (1.0 + Math.sin(u)) + (2.0 * (1.0 - Math.cos(u) / 2.0)) * Math.cos(v + Math::PI)
          z = -8.0 * Math.sin(u)
        end

        y = -2.0 * (1.0 - Math.cos(u) / 2.0) * Math.sin(v)

        target.set(x, y, z)
      }
    end

    def self.plane(width, height)
      -> (u, v, target = Vector3.new) {
        x = u.to_f * width.to_f
        y = 0.0
        z = v.to_f * height.to_f

        target.set(x, y, z)
      }
    end

    def self.mobius
      -> (u, t, target = Vector3.new) {
        # flat mobius strip
        # http://www.wolframalpha.com/input/?i=M%C3%B6bius+strip+parametric+equations&lk=1&a=ClashPrefs_*Surface.MoebiusStrip.SurfaceProperty.ParametricEquations-
        u = u - 0.5
        v = 2.0 * Math::PI * t

        a = 2.0

        x = Math.cos(v) * (a + u * Math.cos(v / 2.0))
        y = Math.sin(v) * (a + u * Math.cos(v / 2.0))
        z = u * Math.sin(v / 2)

        target.set(x, y, z)
      }
    end

    def self.mobius3d
      -> (u, t, target = Vector3.new) {
        # volumetric mobius strip

        u *= Math::PI
        t *= 2.0 * Math::PI

        u = u * 2.0
        phi = u / 2.0
        major = 2.25
        a = 0.125
        b = 0.65

        x = a * Math.cos(t) * Math.cos(phi) - b * Math.sin(t) * Math.sin(phi)
        z = a * Math.cos(t) * Math.sin(phi) + b * Math.sin(t) * Math.cos(phi)
        y = (major + x) * Math.sin(u)
        x = (major + x) * Math.cos(u)

        target.set(x, y, z)
      }
    end
  end
end