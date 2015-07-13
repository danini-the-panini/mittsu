require 'minitest_helper'

class TestMittsu < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Mittsu::VERSION
  end
end
