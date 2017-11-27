require "test_helper"

class BaseTest < Minitest::Test
  def test_initializer
    base = MachineChair::Models::Base.new(1)
    assert_equal 1, base.id
  end

  def test_comparing_objects
    base = MachineChair::Models::Base.new(1)
    assert_equal MachineChair::Models::Base.new(1), base
  end

  def test_hash_objects
    base1 = MachineChair::Models::Base.new(1)
    base2 = MachineChair::Models::Base.new(2)
    assert MachineChair::Models::Base.new(1).hash == base1.hash
    assert MachineChair::Models::Base.new(1).hash != base2.hash
  end
end
