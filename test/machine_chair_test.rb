require "test_helper"

class MachineChairTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MachineChair::VERSION
  end
end
