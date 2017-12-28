module MachineChair
  module Models
    class Article
      include MachineChair::Modules::Article

      def initialize(id, name = nil)
        @id = id
        @name = name
      end
    end
  end
end
