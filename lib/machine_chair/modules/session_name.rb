module MachineChair
  module Modules
    module SessionName
      include MachineChair::Modules::Base
      attr_accessor :priority

      def set_priority
        @priority = 0
      end

      def down_priority
        @priority -= 1
      end
    end
  end
end
