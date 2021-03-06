module MachineChair
  module Models
    class Keyword
      include MachineChair::Modules::Base
      attr_reader :id, :name

      def initialize(id, name = nil)
        @id = id
        @name = name
      end
    end
  end
end
