module Mittsu
  class DynamicBufferAttribute < Mittsu::BufferAttribute
    UpdateRange = Struct.new(:offset, :count)

    attr_accessor :update_range

    def initialize(array, item_size)
      super
      @update_range = UpdateRange.new(0, -1)
    end

    def clone
      Mittsu::DynamicBufferAttribute(self.array.dup, self.item_size)
    end
  end
end
