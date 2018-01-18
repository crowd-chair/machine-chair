module MachineChair
  module Models
    class Article
      include MachineChair::Modules::Base
      attr_reader :id, :name, :keywords, :authors, :ng_days

      def initialize(id, name = nil, keywords: [], authors: [], ng_days: [])
        @id = id
        @name = name
        @keywords = keywords
        @authors = authors
        @ng_days = ng_days
      end
    end
  end
end
