module MachineChair
  module Models
    class SessionFrame
      attr_accessor :frames

      def initialize(frames = {})
        @frames = frames.dup
      end

      def limit(slot)
        @frames[slot]
      end

      def max
        @frames.keys.max
      end

      def min
        @frames.keys.min
      end
    end
  end
end
