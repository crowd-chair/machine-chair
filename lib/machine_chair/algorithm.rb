module MachineChair
  class Algorithm

    # @param [MachineChair::State] state アルゴリズムの状態を表したクラス
    # @param [MachineChair::Models::Parameter] param アルゴリズムのパラメータ
    # @param [MachineChair::Models::Frame] frame セッション作成可能枠
    # @option [Bool] :is_test 動作実験用
    # @option [:use_keyword or :use_bidding] :calc Qulityの計算方法でキーワードを用いるか，投票結果を用いるか
    # @return [MachineChair::Models::Session] session 生成したセッションの集合を返す
    def propose(state, param, frame, is_test: false, calc: :use_keyword)
      all_articles = state.articles.dup
      session = MachineChair::Models::Session.new(parameter: param)
      while state.is_continued? do
        if block_given?
          rate = 100 * (all_articles.size - state.articles.size) / all_articles.size.to_f
          yield(rate.to_i)
        end

        seed = state.articles.max_by{|article| state.difficulty(article)}
        candidates = state.find_session_names(seed)

        _min = frame.min
        _max = frame.max

        groups = []
        _min.upto(_max).each{ |slot|
          next if session.count_groups_with_slot(slot) >= frame.limit(slot)
          candidates.each { |candidate|
            articles = state.find_articles(candidate)
            next if articles.size < slot

            articles = articles - [seed]

            # [NOTE] 高速化処理
            # Difficultyが高い論文上位X件のみを使う
            prune_size = 10
            pruned_articles = []
            biddings = articles
              .map{|article| MachineChair::Models::Bidding.new(candidate, article)}
              .map{|bidding| state.find_bidding(bidding)}
            (1..5).each do |rank|
              pruned_articles.concat biddings.select{|b| b.rank == rank}.map{|b| b.article}
              break if pruned_articles.size >= prune_size
            end
            articles = pruned_articles

            articles.combination(slot - 1).map{ |_group|
              group = [seed] + _group
              next if is_satisfy_constraints(group)
              score = state.calc_group_score(candidate, group, calc: calc)
              groups << MachineChair::Models::SessionGroup.new(candidate, group, score: score, seed: seed)

              # 動作確認用
              break if is_test
            }
          }
        }
        best_group = groups.max_by{|group| group.group_score(param)}

        if best_group
          state.remove_articles(best_group.articles)
          state.update(best_group)
          session.append best_group
        else
          state.remove_articles([seed])
          session.remained_articles << seed
        end
      end
      session
    end

    private

    def is_satisfy_constraints(group)
      # 著者に半分以上同じ人がいた場合 true
      author_groups = group.map{ |article|
        article.authors
      }.flatten.group_by(&:itself).map {|k, v| [k, v.size] }
      author_counts = Hash[author_groups]
      max_count = author_counts.values.max
      return true if max_count > group.size.to_f / 2

      # 全行程でNGだった場合 true
      days = 3
      group_ng_days = group.map{ |article| article.ng_days}.flatten.uniq.size
      return true if group_ng_days >= days

      false
    end

    def find_best_group_by(state, seed, candidate, slot, param)
      articles = state.find_articles(candidate)
      return nil if articles.size < slot

      # グループのスコアを求めてその中の最大スコアを持つグループを返す
      # [TODO] 高速化させる必要がある
      articles = articles - [seed]
      best_group = articles.combination(slot - 1).map{ |_group|
        group = [seed] + _group
        # 制約を満たしていない場合はnilを返す
        if is_satisfy_constraints(group)
          nil
        else
          score = state.calc_group_score(session_name, group)
          MachineChair::Models::SessionGroup.new(session_name, group, score: score, seed: seed)
        end
      }.compact.max_by{|g| g.group_score(param)}
    end
  end
end
