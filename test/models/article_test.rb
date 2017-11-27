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

  def test_sub_objects
    ids = [1,2,3,4,5]
    articles = ids.map{ |id|
      MachineChair::Models::Article.new(id)
    }

    sub_ids = [3,4,5]
    sub_articles = sub_ids.map{ |id|
      MachineChair::Models::Article.new(id)
    }

    articles = articles - sub_articles
    assert_equal 2, articles.size
  end
end
