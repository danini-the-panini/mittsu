module RefineObject
  refine Object do
    def clone
      super
      # do some other things....
    end
  end
end

require 'minitest_helper'

class TestMittsu < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Mittsu::VERSION
  end
end
