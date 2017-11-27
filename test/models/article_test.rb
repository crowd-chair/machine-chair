require "test_helper"

class ArticleTest < Minitest::Test
  def test_initializer
    article = MachineChair::Models::Article.new(1)
    assert_equal 1, article.id
  end

  def test_comparing_objects
    article = MachineChair::Models::Article.new(1)
    assert_equal MachineChair::Models::Article.new(1), article
  end

  def test_hash_objects
    article1 = MachineChair::Models::Article.new(1)
    article2 = MachineChair::Models::Article.new(2)
    assert MachineChair::Models::Article.new(1).hash == article1.hash
    assert MachineChair::Models::Article.new(1).hash != article2.hash
  end
end
