module MachineChair
  module Models
    class Keyword
      include MachineChair::Modules::Keyword

      def initialize(id, name = nil)
        @id = id
        @name = name
      end
    end
  end
end
