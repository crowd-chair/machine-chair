module MachineChair
  class State
    attr_reader :session_names, :articles, :biddings, :session_frame

    def initialize(session_names: [], articles: [], biddings: [], frames: {})
      @session_names = session_names.dup
      @articles = articles.dup
      @biddings = biddings.dup
      @session_frame = MachineChair::Models::SessionFrame.new(frames.dup)

      @session_names.each{|s| s.set_priority}
      init_cache
    end

    def init_cache
      @cache = Hash.new
      @cache[:bidding] = init_bidding_cache
      @cache[:score] = init_score_cache
    end

    def remove(articles: [])
      @articles -= articles
      @biddings -= @biddings.select{|b| articles.include? b.article}
      @cache[:bidding] = init_bidding_cache
    end

    def update(group)
      update_priority(group.session_name)
      @session_frame.update(group)

      @cache[:score][:priority] = normalize_priority_cache
      @cache[:score][:difficulty] = normalize_difficulty_cache
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
      @cache[:score][:difficulty][article.hash]
    end

    def priority(session_name)
      @cache[:score][:priority][session_name.hash]
    end

    def quality(session_name, article)
      bidding = MachineChair::Models::Bidding.new(session_name, article)
      @cache[:score][:quality][bidding.hash]
    end

    def is_continued?
      !is_finished?
    end

    def is_finished?
      @articles.empty?
    end

    def calc_group_score(session_name, articles)
      _d = articles.map{|a| difficulty(a)}.sum
      _q = articles.map{|a| quality(session_name, a)}.sum
      _p = priority(session_name)
      MachineChair::Models::Score.new(difficulty: _d, quality: _q, priority: _p)
    end

    def calc_score(session_name, article)
      _d = difficulty(article)
      _q = quality(session_name, article)
      _p = priority(session_name)
      MachineChair::Models::Score.new(difficulty: _d, quality: _q, priority: _p)
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

    def init_score_cache
      {
        difficulty: normalize_difficulty_cache,
        priority: normalize_priority_cache,
        quality: normalize_quality_cache
      }
    end

    def calc_difficulty(article)
      session_names = @cache[:bidding][:session_name][article.hash]
      return 0.0 if session_names.nil? || session_names.empty?

      articles = session_names.map { |s|
        @cache[:bidding][:article][s.hash]
      }.flatten.uniq
      return 1.0 / articles.size.to_f
    end

    def calc_priority(session_name)
      session_name.priority
    end

    def calc_quality(bidding)
      @cache[:bidding][:bidding][bidding.hash].weight
    end

    def normalize_difficulty_cache
      _h = @articles.map{|a| a.hash}
      _d = @articles.map{|a| calc_difficulty(a)}.normalize
      Hash[*[_h, _d].transpose.flatten]
    end

    def normalize_quality_cache
      _h = @biddings.map{|b| b.hash}
      _q = @biddings.map{|b| calc_quality(b)}.normalize
      Hash[*[_h, _q].transpose.flatten]
    end

    def normalize_priority_cache
      _h = @session_names.map{|h| h.hash}
      _p = @session_names.map{|s| calc_priority(s)}.normalize
      Hash[*[_h, _p].transpose.flatten]
    end

    def update_priority(session_name)
      session_name.down_priority
    end
  end
end
