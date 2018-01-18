module MachineChair
  module Models
    class SessionGroup
      attr_reader :session_name, :articles, :score, :seed

      def initialize(session_name, articles, score: nil, seed: nil)
        @session_name = session_name
        @articles = articles
        @score = score
        @seed = seed
      end

      def slot
        articles.size
      end

      def group_score(param)
        @score.calc(param)
      end

      def group_point(param)
        @score.priority + @score.quality
      end
    end
  end
end
