module MachineChair
  module Modules
    module SessionFrame
      attr_accessor :frames

      def available?(slot)
        @frames[slot] && @frames[slot] > 0
      end

      def unavailable?(slot)
        !available?(slot)
      end

      def max
        _min = @frames.keys.min
        _max = @frames.keys.max
        _max.downto(_min).each do |slot|
          return slot if available?(slot)
        end
        0
      end

      def min
        _min = @frames.keys.min
        _max = @frames.keys.max
        _min.upto(_max).each do |slot|
          return slot if available?(slot)
        end
        0
      end

      def update(session_group)
        raise "No Available Frame" unless available? session_group.slot
        @frames[session_group.slot] -= 1
      end
    end
  end
end
