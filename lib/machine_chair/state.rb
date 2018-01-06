module MachineChair
  class State
    using MachineChair::Extensions
    attr_reader :session_names, :articles, :biddings, :session_frame

    def initialize(session_names: [], articles: [], biddings: [], frames: {}, keywords: [], keyword_relations: [])
      @session_names = session_names.dup
      @articles = articles.dup
      @biddings = biddings.dup
      @keywords = keywords.dup
      @keyword_relations = keyword_relations.dup
      @session_frame = MachineChair::Models::SessionFrame.new(frames.dup)

      @session_names.each{|s| s.set_priority}

      init_cache
    end

    def dup
      self.class.new(
        session_names: @session_names,
        articles: @articles,
        biddings: @biddings,
        frames: @session_frame.frames,
        keywords: @keywords,
        keyword_relations: @keyword_relations
      )
    end

    def init_cache
      @cache = Hash.new
      @cache[:bidding] = init_bidding_cache
      @cache[:keyword] = init_keyword_cache
      @cache[:vector] = init_keyword_vector
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

    def cos(a1, a2)
      @cache[:score][:cos][to_cos_hash(a1,a2)]
    end

    def is_continued?
      !is_finished?
    end

    def is_finished?
      @articles.empty?
    end

    def calc_group_score(session_name, articles)
      _d = articles.map{|a| difficulty(a)}.sum
      _q = articles.combination(2).map{|a| cos(*a)}.sum
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
        priority: normalize_priority_cache,
        quality: normalize_quality_cache,
        cos: cache_all_cos
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


    def cache_all_cos
      # 時間がかかる処理
      cos_cache = Hash.new
      @articles.each{|a1|
        @articles.each{|a2|
          next if a1 == a2
          next if cos_cache[to_cos_hash(a1, a2)]
          if cos_cache[to_cos_hash(a2, a1)]
            cos_cache[to_cos_hash(a1, a2)] = cos_cache[to_cos_hash(a2, a1)]
            next
          end
          v1 = @cache[:vector][:article][a1.hash]
          v2 = @cache[:vector][:article][a2.hash]
          cos_cache[to_cos_hash(a1, a2)] = v1.cos(v2)
        }
      }
      cos_cache.normalize
      
      # 高速化Ver(厳密な標準化をしない)
      # @session_names.each{|s|
      #   as = @cache[:bidding][:article][s.hash]
      #   as.product(as).each{|a1, a2|
      #     next if a1 == a2
      #     next if cos_cache[to_cos_hash(a1, a2)]
      #     if cos_cache[to_cos_hash(a2, a1)]
      #       cos_cache[to_cos_hash(a1, a2)] = cos_cache[to_cos_hash(a2, a1)]
      #       next
      #     end
      #     v1 = @cache[:vector][:article][a1.hash]
      #     v2 = @cache[:vector][:article][a2.hash]
      #     cos_cache[to_cos_hash(a1, a2)] = v1.cos(v2)
      #   }
      # }
      # cos_cache.normalize
    end

    def to_cos_hash(a1, a2)
      [a1.hash, a2.hash].hash
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
