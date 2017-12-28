module MachineChair
  module Models
    class Parameter
      attr_reader :difficulty, :priority, :quality

      def initialize(difficulty: 0.0, priority: 0.0, quality: 0.0)
        @difficulty = difficulty
        @priority = priority
        @quality = quality
        @difficulty = 1.0 - priority - quality unless difficulty
        normalize!
      end

      def normalize!
        norm = @difficulty + @priority + @quality
        @difficulty /= norm
        @priority /= norm
        @quality /= norm
      end
    end
  end
end
