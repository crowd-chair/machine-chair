module MachineChair
  module Models
    class Article
      include MachineChair::Modules::Base
      attr_reader :id, :name, :keywords, :authors

      def initialize(id, name = nil, keywords: [], authors: [])
        @id = id
        @name = name
        @keywords = keywords
        @authors = authors
      end
    end
  end
end
