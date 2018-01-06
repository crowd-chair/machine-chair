module MachineChair
  module Models
    class SessionName
      include MachineChair::Modules::Base
      attr_reader :id, :name
      attr_accessor :priority

      def initialize(id, name = nil)
        @id = id
        @name = name
      end




      def set_priority
        @priority = 0
      end

      def down_priority
        @priority -= 1
      end
    end
  end
end
