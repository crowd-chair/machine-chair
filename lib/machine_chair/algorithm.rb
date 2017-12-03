module MachineChair
  class Algorithm
    class << self
      EPSILON = 10e-8

      def propose(state, params: {
          quality: 0.2,
          priority: 0.2,
          difficulty: 0.8
        })
        groups = []
        while state.is_continued? do
          # 計算量を減らすためにグループを作成するためのセッションを絞り込む
          # sessions = sieve(state)
          sessions = state.sessions

          # 選択されたセッション集合から一番スコアの高いグループを作成する
          group = select(state, sessions, params)

          if group
            state = state.update_group(group)
            groups << group
          else
            state = state.update_sessions(sessions)
          end
        end
        return groups, state
      end

      # 一番Difficultyが高い投稿が投票しているセッションに絞り込む
      def sieve(state)
        arg_max = state.articles.max_by{|a| state.difficulty(a)}
        return state.find_sessions(arg_max)
      end

      # セッションから一番スコアの高いグループを作成する
      def select(state, sieves, params)
        state.frame.min.upto(state.frame.max).each { |slot|
          next unless state.frame.available? slot
          createbles = sieves.select { |session|
            state.find_articles(session).size >= slot
          }
          next if createbles.empty?

          return group_with_max_score(state, createbles, slot, params)
        }
        nil
      end

      private

      def group_with_max_score(state, sessions, slot, params)
        groups = sessions.map { |session|
          create_max_group(state, session, slot, params)
        }
        return groups.max_by { |group|
          score_group(state, group, params)
        }
      end

      def create_max_group(state, session, slot, params)
        articles = state.find_articles(session).sort_by{ |article|
          bidding = MachineChair::Models::Bidding.new(article, session)
          score(state, article, bidding, session, params)
        }.reverse[0...slot]
        MachineChair::Models::Group.new(session, articles)
      end

      def score(state, article, bidding, session, params)
        _q = params[:quality]
        _p = params[:priority]
        _d = params[:difficulty] || 1.0 - q_param.to_f - p_param.to_f
        quality = state.quality(bidding)
        priority = state.priority(session)
        difficulty = state.difficulty(article)
        return _d * difficulty + _p * priority + _q * quality
      end

      def score_group(state, group, params)
        group.articles.inject(0) { |total, article|
          session = group.session
          bidding = MachineChair::Models::Bidding.new(article, session)
          total + score(state, article, bidding, session, params)
        } / group.slot.to_f
      end

    end
  end
end
