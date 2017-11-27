require "machine_chair/models/base"

module MachineChair
  module Models
    class Session < MachineChair::Models::Base
      attr_accessor :id, :name, :priority

      def initialize(id, name)
        @id = id
        @name = name
        @priority = -1
      end

      def down_priority
        @priority = @priority - 1
      end

    end
  end
end
