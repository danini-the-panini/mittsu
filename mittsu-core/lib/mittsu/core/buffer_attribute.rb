module Mittsu
  class BufferAttribute
    attr_accessor :array, :item_size, :needs_update

    def initialize(array, item_size)
      @array = array
      @item_size = item_size

      @needs_update = false
    end

    def length
      @array.length
    end

    def copy_at(index1, attribute, index2)
      index1 *= @item_size
      index2 *= attribute.item_size

      @item_size.times do |i|
        @array[index1 + i] = attribute.array[index2 + i]
      end

      self
    end

    def set(value, offset)
      offset ||= 0

      @array[offset, value.length] = value

      self
    end

    def set_x(index, x)
      @array[index * @item_size] = x

      self
    end

    def set_y(index, y)
      @array[index * @item_size + 1] = y

      self
    end

    def set_z(index, z)
      @array[index * @item_size + 2] = z

      self
    end

    def get_x(index)
      @array[index * @item_size]
    end

    def get_y(index)
      @array[index * @item_size + 1]
    end

    def get_z(index)
      @array[index * @item_size + 2]
    end

    def set_xy(index, x, y)
      index *= @item_size

      @array[index    ] = x
      @array[index + 1] = y

      self
    end

    def set_xyz(index, x, y, z)
      index *= @item_size

      @array[index    ] = x
      @array[index + 1] = y
      @array[index + 2] = z

      self
    end

    def set_xyzw(index, x, y, z, w)
      index *= @item_size

      @array[index    ] = x
      @array[index + 1] = y
      @array[index + 2] = z
      @array[index + 3] = w

      self
    end

    def clone
      BufferAttribute.new(@array.clone, @item_size)
    end
  end
end
