module MachineChair
  class Algorithm
    class << self
      def propose_session(state, param, prune: 5)
        session = MachineChair::Models::Session.new(parameter: param)
        while state.is_continued? do
          # 計算量を減らすためにグループを作成するためのセッションを絞り込む
          article_seeds = prune_articles(state, total: prune)
          # セッションの候補を投稿から見つける
          session_candidates = candidate_sessions(state, article_seeds)
          # 選択されたセッション集合から一番スコアの高いグループを作成する
          group = find_best_group(state, session_candidates, param)
          if group
            state.remove(articles: group.articles)
            state.update(group)
            session.append group
          else
            state.remove(articles: article_seeds)
            session.append_remained_articles article_seeds
          end
        end
        session.session_frame = state.session_frame
        return session
      end

      def prune_articles(state, total: nil)
        return state.articles if !total || total <= 0
        state.articles.sort_by{|a| -1.0 * state.difficulty(a)}[0...total]
      end

      def candidate_sessions(state, article_seeds = [])
        article_seeds.map{|a| state.find_session_names(a)}.flatten.uniq
      end

      def find_best_group(state, candidates, param)
        _max = state.session_frame.max
        _min = state.session_frame.min
        _min.upto(_max).each{ |slot|
          best_group = candidates.map{ |c|
            group = find_best_group_of_session_name(state, c, slot, param)
          }.compact.max_by{|g| g.group_score(param)}
          return best_group if best_group
        }
        nil
      end

      private

      def find_best_group_of_session_name(state, session_name, slot, param)
        articles = state.find_articles(session_name)
        return nil if articles.size < slot
        # best_group = articles.combination(slot).map{ |a|
        #   score = state.calc_group_score(session_name, a)
        #   MachineChair::Models::SessionGroup.new(session_name, a, score: score)
        # }.max_by{|g| g.group_score(param)}

        # 正解データの近似
        scores = Hash[*[articles, articles.map{|a| state.calc_score(session_name, a)}].transpose.flatten]
        best_group_articles = articles.sort_by{|a| -1.0 * scores[a].calc(param)}[0...slot]
        group_score = state.calc_group_score(session_name, best_group_articles)
        best_group = MachineChair::Models::SessionGroup.new(session_name, best_group_articles, score: group_score)

        if best_group
          puts "---BestGroup---"
          puts "Session Name: #{session_name.name}"
          puts "Article Size: #{best_group.articles.size}"
          puts "From Article Size: #{articles.size}"
        end
        best_group
      end
    end
  end
end
