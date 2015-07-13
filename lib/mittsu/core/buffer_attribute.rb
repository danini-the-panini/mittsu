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

    def setX(index, x)
      @array[index * @item_size] = x

      self
    end

    def setY(index, y)
      @array[index * @item_size + 1] = y

      self
    end

    def setZ(index, z)
      @array[index * @item_size + 2] = z

      self
    end

    def setXY(index, x, y)
      index *= @item_size

      @array[index    ] = x
      @array[index + 1] = y

      self
    end

    def setXYZ(index, x, y, z)
      index *= @item_size

      @array[index    ] = x
      @array[index + 1] = y
      @array[index + 2] = z

      self
    end

    def setXYZW(index, x, y, z, w)
      index *= @item_size

      @array[index    ] = x
      @array[index + 1] = y
      @array[index + 2] = z
      @array[index + 3] = z

      self
    end

    def clone
      BufferAttribute.new(@array.clone, @item_size)
    end
  end
end
