require "machine_chair/models/group"

module MachineChair
  class Algorithm
    EPSILON = 10e-8

    class << self

      def propose(state, alpha: 0.5, beta: 0.5)
        groups = []
        while state.is_continued? do
          sessions = sieve(state, alpha: alpha)
          group = select(state, sessions, beta: beta)

          if group
            state = state.update_group(group)
            groups << group
          else
            state = state.update_sessions(sessions)
          end
        end
        groups, state
      end

      # Sieve sessions with alpha param
      def sieve(state, alpha: 0.5)
        sieve_scores = state.sessions.map{ |session|
          sieve_score(state, session, alpha: alpha)
        }
        max_sieve_score = sieve_scores.max

        state.sessions.zip(sieve_scores).reject { |_, score|
          (score - max_sieve_score).abs > EPSILON
        }.map{ |session, _| session }
      end

      # Select group in sieved sessions with beta param
      def select(state, sieves, beta: 0.5)
        state.frame.max.downto(state.frame.min).each { |slot|
          next unless state.frame.available? slot
          createbles = sieves.select { |session|
            find_articles(state, session).size >= slot
          }
          next if createbles.empty?

          return createbles.map { |session|
            create_group(state, session, slot, beta: beta)
          }.max_by{ |group|
            group_score(state, group, beta: beta)
          }
        }
        nil
      end

      private

      def sieve_score(state, session, alpha: alpha)
        articles = find_articles(state, session)
        difficulty = articles.map { |article|
          state.difficulty(article)
        }.max
        priority = state.priority(session)

        difficulty * alpha + priority * (1.0 - alpha)
      end

      def bidding_score(state, session, article, beta: beta)
        bidding = MachineChair::Models::Bidding.new(session, article)
        quality = state.quality(bidding)
        difficulty = state.difficulty(article)

        difficulty * beta + quality * (1.0 - beta)
      end

      def create_group(state, session, slot, beta: beta)
        find_articles(state, session).sort_by{ |article|
          bidding_score(state, session, article, beta: beta)
        }.reverse[0...slot]

        MachineChair::Models::Group.new(session, articles)
      end

      def group_score(state, group, beta: beta)
        group.articles.inject{ |total, article|
          total + bidding_score(state, session, article, beta: beta)
        } / group.slot.to_f
      end

    end
  end
end
