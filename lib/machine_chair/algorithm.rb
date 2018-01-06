module MachineChair
  class Algorithm

    # @option [bool] use_keyword キーワードを使うかBiddingのみを使うか(default: true)
    # @option [bool] greedy 貪欲法の近似解でキーワードのスコアを付けるかどうか(default: false)
    def initialize(use_keyword: true, greedy: false, prunes: 5)
      @use_keyword = use_keyword
      @greedy = greedy
      @prunes = prunes
    end

    # @param [MachineChair::State] state アルゴリズムの状態を表したクラス
    # @param [MachineChair::Models::Parameter] param アルゴリズムのパラメータ
    # @option [Integer] prune 投稿を何件選択するか(default: 5)
    # @return [MachineChair::Models::Session] session 提案セッションを返す
    def propose_session(state, param)
      session = MachineChair::Models::Session.new(parameter: param)
      while state.is_continued? do
        # 計算量を減らすためにグループを作成するためのセッションを絞り込む
        article_seeds = prune_articles(state)
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
      session
    end

    def prune_articles(state)
      return state.articles if !@prunes || @prunes <= 0
      state.articles.sort_by{|a| -1.0 * state.difficulty(a)}[0...@prunes]
    end

    def candidate_sessions(state, article_seeds = [])
      article_seeds.map{|a| state.find_session_names(a)}.flatten.uniq
    end

    def find_best_group(state, candidates, param)
      _min = state.session_frame.min
      _max = state.session_frame.max
      best_group_candidates = []
      _max.downto(_min).each{ |slot|
        next if state.session_frame.unavailable? slot
        best_group_candidates.concat candidates.map{ |c|
          group = find_best_group_by(state, c, slot, param)
        }.compact
        break if best_group_candidates.size > 0
      }
      return nil if best_group_candidates.empty?

      best_group = best_group_candidates.max_by{|g| g.group_score(param)}
      best_group
    end

    private

    def find_best_group_by(state, session_name, slot, param)
      articles = state.find_articles(session_name)
      return nil if articles.size < slot

      best_group = nil
      if !@use_keyword
        # Biddingによる近似解
        scores = Hash[*[articles, articles.map{|a| state.calc_score(session_name, a)}].transpose.flatten]
        best_group_articles = articles.sort_by{|a| -1.0 * scores[a].calc(param)}[0...slot]
        group_score = state.calc_group_score(session_name, best_group_articles)
        best_group = MachineChair::Models::SessionGroup.new(
          session_name, best_group_articles, score: group_score
        )
      elsif @greedy
        # 近似解
        # 各投稿に対して一番小さいグループを作り貪欲法でグループを作成
        best_group = articles.map{ |a|
          group = []
          candidates = articles.dup
          (0...slot).each { |i|
            if i == 0
              group << a
              candidates.delete a
              next
            end
            max_candidate = candidates.map{ |c|
              [c, state.calc_group_score(session_name, [*group, c])]
            }.max_by{|_, score| score.calc(param)}.first
            group << max_candidate
            candidates.delete max_candidate
          }
          score = state.calc_group_score(session_name, group)
          MachineChair::Models::SessionGroup.new(session_name, group, score: score)
        }.max_by{|g| g.group_score(param)}
      else
        # グループのスコアを求めてその中の最大スコアを持つグループを返す
        # [TODO] 高速化させる必要がある
        best_group = articles.combination(slot).map{ |a|
          score = state.calc_group_score(session_name, a)
          MachineChair::Models::SessionGroup.new(session_name, a, score: score)
        }.max_by{|g| g.group_score(param)}
      end
      best_group
    end
  end
end
