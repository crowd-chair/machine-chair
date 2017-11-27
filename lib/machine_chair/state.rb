module MachineChair
  class State
    attr_accessor :sessions, :articles, :biddings, :frame

    def initialize(sessions, articles, biddings, frame)
      @sessions = sessions
      @articles = articles
      @biddings = biddings
      @frame = frame

      @bidding_caches = update_bidding_cache
      @score_caches = {
        difficulty: update_normalized_difficulty_cache,
        quality: update_normalized_quality_cache,
        priority: update_normalized_priority_cache
      }
    end

    def find_articles(session)
      @bidding_caches[:to_articles][session.hash]
    end

    def find_sessions(article)
      @bidding_caches[:to_sessions][article.hash]
    end

    def difficulty(article)
      @score_caches[:difficulty][article.hash]
    end

    def priority(session)
      @score_caches[:priority][session.hash]
    end

    def quality(bidding)
      @score_caches[:quality][bidding.hash]
    end

    def update_sessions(sessions)
      next_sessions = @sessions - sessions
      next_biddings = @biddings - @biddings.select { |bidding|
        sessions.include? bidding.session
      }.flatten

      MachineChair::State.new(
        next_sessions,
        @articles,
        next_biddings,
        @frame
      )
    end

    def update_group(group)
      next_articles = @articles - group.articles
      next_biddings = @biddings - @biddings.select { |bidding|
        group.articles.include? bidding.article
      }
      next_frame = @frame.put group.slot

      MachineChair::State.new(
        @sessions,
        next_articles,
        next_biddings,
        next_frame
      )
    end

    def is_continued?
      !is_finished?
    end

    def is_finished?
      @sessions.empty? || @articles.empty? || @biddings.empty?
    end

    private

    def calc_difficulty(article)
      sessions = @bidding_caches[:to_sessions][article.hash]
      articles = sessions.map { |session|
        @bidding_caches[:to_articles][session.hash]
      }.flatten.uniq

      if articles.empty?
        0.0
      else
        1.0 / articles.size.to_f
      end
    end

    def calc_priority(session)
      session.priority.to_f.abs
    end

    def calc_quality(bidding)
      bidding.tie_strength.to_f
    end

    def update_bidding_cache
      to_sessions = Hash.new
      to_articles = Hash.new
      @biddings.each { |bidding|
        to_sessions[bidding.article.hash] ||= []
        to_sessions[bidding.article.hash] << bidding.session
        to_articles[bidding.session.hash] ||= []
        to_articles[bidding.session.hash] << bidding.article
      }
      return {
        to_sessions: to_sessions,
        to_articles: to_articles
      }
    end

    def update_normalized_difficulty_cache
      hash = Hash.new
      diffs = @articles.map { |article|
        calc_difficulty(article)
      }
      max_diff = diffs.max
      @articles.zip(diffs).each { |article, diff|
        hash[article.hash] = diff / max_diff
      }
      hash
    end

    def update_normalized_quality_cache
      hash = Hash.new
      @biddings.each { |bidding|
        hash[bidding.hash] = bidding.tie_strength
      }
      hash
    end

    def update_normalized_priority_cache
      hash = Hash.new
      pris = @sessions.map { |session|
        calc_priority(session)
      }
      min_pri = pris.max
      @sessions.zip(pris).each { |session, pri|
        hash[session.hash] = (min_pri - pri) / min_pri
      }
      hash
    end

  end
end
