module MachineChair
  module Models
    class Frame
      attr_reader :state

      def initialize(slot_list)
        @state = Hash.new
        slot_list.each do |slot, total_empties|
          @state[slot] = total_empties
        end
      end

      def available(slot)
        return @state[slot] && @state[slot] != 0
      end

      def max_slot
        @state.keys.sort{|a, b| b <=> a }.each do |slot|
          return slot if self.available slot
        end
        return nil
      end

      def min_slot
        @state.keys.sort{|a, b| a <=> b }.each do |slot|
          return slot if self.available slot
        end
        return nil
      end

      def put_in(slot)
        raise unless self.available slot
        
        @next_state = @state.clone
        @next_state[slot] = @next_state[slot] - 1
        Frame.new(@next_state)
      end
    end
  end
end
