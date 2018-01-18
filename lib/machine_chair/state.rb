module MachineChair
  class State
    using MachineChair::Extensions
    attr_reader :session_names, :articles, :biddings, :keywords, :keyword_relations, :session_name_limit

    def initialize(
      session_names: [],
      articles: [],
      biddings: [],
      keywords: [],
      keyword_relations: [],
      session_name_limit: 5
    )
      @session_names = session_names.dup
      @articles = articles.dup
      @biddings = biddings.dup
      @keywords = keywords.dup
      @keyword_relations = keyword_relations.dup
      @session_name_limit = session_name_limit

      @session_names_counter = {}
      @session_names.each {|name|
        @session_names_counter[name.hash] = 0
      }
      @max_biddings = 5

      init_cache
    end

    def dup
      self.class.new(
        session_names: @session_names,
        articles: @articles,
        biddings: @biddings,
        keywords: @keywords,
        keyword_relations: @keyword_relations,
        session_name_limit: @session_name_limit
      )
    end

    def init_cache
      @cache = Hash.new
      @cache[:bidding] = init_bidding_cache
      @cache[:keyword] = init_keyword_cache
      @cache[:vector] = init_keyword_vector
      @cache[:score] = init_score_cache
    end

    def remove_articles(articles)
      @articles -= articles
      @biddings -= @biddings.select{|b| articles.include? b.article}
      @cache[:bidding] = init_bidding_cache
      @cache[:score][:difficulty] = normalize_difficulty_cache
    end

    def update(group)
      update_counter(group.session_name)
    end

    def find_articles(session_name)
      @cache[:bidding][:article][session_name.hash]
    end

    def find_session_names(article)
      @cache[:bidding][:session_name][article.hash]
    end

    def find_bidding(bidding)
      @cache[:bidding][:bidding][bidding.hash]
    end

    def difficulty(article)
      @cache[:score][:difficulty][article.hash] || 1.0
    end

    # articlesを覗いた論文のDifficultyの平均を計算
    # このDifficultyが低い方が仲間を見つけやすい
    def calc_r_difficulty(articles)
      r_articles = @articles - articles
      return 0.0 if r_articles.empty?
      # r_biddings = @biddings - @biddings.select{|b| articles.include? b.article}
      # hash = normalize_difficulty_cache_detect(r_articles, r_biddings)
      # r_dif = 1.0 - r_articles.map{|a| hash[a.hash]}.mean
      r_dif = 1.0 - r_articles.map{|a| difficulty(a)}.mean
    end

    def cos(a1, a2)
      @cache[:score][:cos][to_cos_hash(a1,a2)]
    end

    def is_continued?
      !is_finished?
    end

    def is_finished?
      @articles.empty?
    end

    def calc_group_score(session_name, articles, calc: :use_keyword)
      _d = calc_r_difficulty(articles)
      _p = calc_group_priority(session_name)
      _q = nil
      if calc == :use_keyword
        _q = calc_group_quality_by_keyword(session_name, articles)
      elsif calc == :use_bidding
        _q = calc_group_quality_by_bidding(session_name, articles)
      else
        _q = calc_group_quality_by_all(session_name, articles)
      end
      # p "Rem: #{@articles.size} d: #{_d}, p: #{_p}, q: #{_q}"
      MachineChair::Models::Score.new(difficulty: _d, quality: _q, priority: _p)
    end

    def calc_group_difficulty(articles)
      articles.map{|a| difficulty(a)}.mean
    end

    def calc_group_priority(session_name)
      count = @session_names_counter[session_name.hash]
      per_count = 1 / @session_name_limit.to_f
      priority = session_name.initial_priority - per_count * count
      return 0 if priority < 0
      priority
    end

    def calc_group_quality_by_all(session_name, articles)
      [
        bidding_score(session_name, articles) * 5.0,
        keyword_similarity(session_name, articles) * 1.0
      ].sum / 6.0
    end

    def calc_group_quality_by_keyword(session_name, articles)
      keyword_similarity(session_name, articles)
    end

    def calc_group_quality_by_bidding(session_name, articles)
      [
        bidding_score(session_name, articles) * 5.0,
        bidding_matching(session_name, articles) * 1.0
      ].sum / 6.0
    end

    def bidding_score(session_name, articles)
      articles.map{|article| calc_bidding_weight(session_name, article)}.mean
    end

    def bidding_matching(session_name, articles)
      all_bidding_names = articles.map{|article| find_session_names(article)}.flatten
      names = all_bidding_names.uniq
      names.select{|name| all_bidding_names.count(name) == articles.size }.size / @max_biddings.to_f
    end

    def keyword_similarity(session_name, articles)
      articles.combination(2).map{|a| cos(*a)}.mean
    end

    def calc_difficulty(article)
      session_names = @cache[:bidding][:session_name][article.hash]
      return 1.0 if session_names.nil? || session_names.empty?

      articles = session_names.map { |s|
        @cache[:bidding][:article][s.hash]
      }.flatten.uniq
      return 1.0 / articles.size.to_f
    end

    def calc_bidding_weight(session_name, article)
      bidding = find_bidding MachineChair::Models::Bidding.new(session_name, article)
      return 0.0 if bidding.nil?
      bidding.weight
    end

    private

    def init_bidding_cache
      cache_article = Hash.new
      cache_session_name = Hash.new
      cache_bidding = Hash.new
      @biddings.each{|b|
        cache_session_name[b.article.hash] ||= []
        cache_article[b.session_name.hash] ||= []

        cache_session_name[b.article.hash] << b.session_name
        cache_article[b.session_name.hash] << b.article
        cache_bidding[b.hash] = b
      }
      {
        article: cache_article,
        session_name: cache_session_name,
        bidding: cache_bidding
      }
    end

    def init_keyword_cache
      cache_article = Hash.new
      cache_keyword = Hash.new
      cache_keyword_relation = Hash.new
      @keyword_relations.each{|r|
        cache_keyword_relation[r.hash] = r
        cache_article[r.keyword.hash] ||= []
        cache_article[r.keyword.hash] << r.article
        cache_keyword[r.article.hash] ||= []
        cache_keyword[r.article.hash] << r.keyword
      }
      {
        relation: cache_keyword_relation,
        article: cache_article,
        keyword: cache_keyword
      }
    end

    def init_keyword_vector
      keyword_vector = Hash.new
      @keywords.each{|k|
        articles = @cache[:keyword][:article][k.hash]
        next unless articles
        list = Hash.new
        biddings = articles.map{|a|
          @cache[:bidding][:session_name][a.hash].map{|s|
            @cache[:bidding][:bidding][MachineChair::Models::Bidding.new(s,a).hash]
          }
        }.flatten
        biddings.each{|b|
          list[b.session_name.hash] = 0 unless list[b.session_name.hash]
          list[b.session_name.hash] += b.weight
        }
        keyword_vector[k.hash] = Vector[*@session_names.map{|s| list[s.hash] || 0}]
      }
      article_vector = Hash.new
      @articles.each{|a|
        keywords = @cache[:keyword][:keyword][a.hash]
        article_vector[a.hash] = keywords.map{|k| keyword_vector[k.hash]}.inject(:+)
      }
      {
        article: article_vector,
        keyword: keyword_vector
      }
    end

    def init_score_cache
      {
        difficulty: normalize_difficulty_cache,
        cos: cache_all_cos
      }
    end

    def cache_all_cos
      cos_cache = Hash.new

      # 高速化Ver(厳密な標準化をしない)
      @session_names.each{|s|
        as = @cache[:bidding][:article][s.hash]
        as.combination(2).each{|a1, a2|
          v1 = @cache[:vector][:article][a1.hash]
          v2 = @cache[:vector][:article][a2.hash]
          cos_cache[to_cos_hash(a1, a2)] = v1.cos(v2)
          cos_cache[to_cos_hash(a2, a1)] = v1.cos(v2)
        }
      }
      cos_cache
    end

    def to_cos_hash(a1, a2)
      [a1.hash, a2.hash].hash
    end

    def normalize_difficulty_cache
      _h = @articles.map{|a| a.hash}
      _d = @articles.map{|a| calc_difficulty(a)}.normalize
      Hash[*[_h, _d].transpose.flatten]
    end

    def normalize_difficulty_cache_detect(articles, biddings)
      _h = articles.map{|a| a.hash}
      cache_articles = {}
      cache_sessions = {}
      biddings.each do |bidding|
        cache_sessions[bidding.article.hash] ||= []
        cache_sessions[bidding.article.hash] << bidding.session_name
        cache_articles[bidding.session_name.hash] ||= []
        cache_articles[bidding.session_name.hash] << bidding.article
      end

      _d = articles.map{|a|
        session_names = cache_sessions[a.hash] || []
        commons = session_names.map{|n| cache_articles[n.hash]}.flatten.uniq
        if commons.size == 0
          1.0
        else
          1.0 / commons.size
        end
      }.normalize
      Hash[*[_h, _d].transpose.flatten]
    end

    def update_counter(session_name)
      @session_names_counter[session_name.hash] += 1
    end
  end
end
