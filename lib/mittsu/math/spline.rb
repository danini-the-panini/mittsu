require 'mittsu/math'

module Mittsu
  class Spline
    Point = Struct.new(:x, :y, :z)
    Length = Struct.new(:chunks, :total)

    attr_accessor :points

    def initialize(points)
      @points = points
      @c = []
      @v3 = Point.new(0.0, 0.0, 0.0)
    end

    def init_from_array(a)
      @points = a.map do |p|
        Point.new(*p.take(3))
      end
    end

    def point(k)
      point = (@points.length - 1) * k
      int_point = point.floor
      weight = point - int_point

      @c[0] = int_point.zero? ? int_point : int_point - 1
      @c[1] = int_point
      @c[2] = int_point > @points.length - 1 ? @points.length - 1 : int_point + 1
      @c[3] = int_point > @points.length - 3 ? @points.length - 1 : int_point + 2

      pa = @points[c[0]]
      pb = @points[c[1]]
      pc = @points[c[2]]
      pd = @points[c[3]]

      w2 = weight * weight
      w3 = weight * w2

      v3.x = interpolate(pa.x, pb.x, pc.x, pd.x, weight, w2, w3)
      v3.y = interpolate(pa.y, pb.y, pc.y, pd.y, weight, w2, w3)
      v3.z = interpolate(pa.z, pb.z, pc.z, pd.z, weight, w2, w3)

      v3
    end

    def control_points_array
      @points.map do |p|
        [ p.x, p.y, p.z ]
      end
    end

    def length(n_sub_divisions = 100)
      point, int_point, old_int_point = 0, 0, 0
      old_position = Mittsu::Vector3.new
      tmp_vec = Mittsu::Vector3.new
      chunk_lengths = []
      total_length = 0

      # first point has 0 length
      chunk_lengths << 0
      n_samples = @points.length * n_sub_divisions
      old_position.copy(@points.first)

      (1...n_samples).each do |i|
        index = i.to_f / n_samples.to_f

        position = self.point(index)
        tmp_vec.copy(position)

        total_length += tmp_vec.distance_to(old_position)

        old_position.copy(position)

        point = (@points.length - 1) * index
        int_point = point.floor

        if (int_point != old_int_point)
          chunk_lengths[int_point] = total_length
          old_int_point = int_point
        end
      end

      # last point ends with total length
      chunk_lengths << total_length
      Length.new(chunk_lengths, total_length)
    end

    def reparametrize_by_arc_length(sampling_coef)
      new_points = []
      tmp_vec = Mittsu::Vector3.new
      sl = self.length

      new_points << tmp_vec.copy(@points[0]).clone

      @points.each_with_index do |p,i|
        #tmp_vec.copy(@points[i-1])
        #linear_distance = tmp_vec.distance_to(p)

        real_distance = sl.chunks[i] - sl.chunks[i - 1]

        sampling = (sampling_coef * real_distance / sl.total).ceil

        index_current = (i.to_f - 1.0) / (@points.length.to_f - 1.0)
        index_next = i.to_f / (@points.length.to_f - 1.0)

        (1...sampling-1).each do |j|
          index = index_current + j * (1.0 / sampling) * (index_next - index_current)

          position = self.point(index)
          new_points << tmp_vec.copy(position).clone
        end

        new_points << tmp_vec.copy(p).clone
      end
      @points = new_points
    end

    private

    def interpolate(p0, p1, p2, p3, t, t2, t3)
      v0 = (p2 - p0) * 0.5
      v1 = (p4 - p1) * 0.5

      (2.0 * (p1 - p2) + v0 + v1) * t3 + (-3.0 * (p1 - p2) - 2.0 * v0 - v1) * t2 + v0 * t + p1?
    end
  end
end
