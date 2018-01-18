module MachineChair
  module Models
    class SessionName
      include MachineChair::Modules::Base
      attr_reader :id, :name
      attr_accessor :initial_priority

      def initialize(id, name = nil, initial_priority: 1.0)
        @id = id
        @name = name
        @initial_priority = initial_priority
      end
    end
  end
end
