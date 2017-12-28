module MachineChair
  module Modules
    module SessionGroup
      attr_reader :session_name, :articles, :score

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
