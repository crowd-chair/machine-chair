module MachineChair
  module Models
    class Score
      attr_reader :difficulty, :priority, :quality

      def initialize(difficulty: 0.0, priority: 0.0, quality: 0.0)
        @difficulty = difficulty
        @priority = priority
        @quality = quality
      end

      def calc(param)
        @difficulty * param.difficulty + @priority * param.priority + @quality * param.quality
      end
    end
  end
end
