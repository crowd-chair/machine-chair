module MachineChair
  module Models
    class KeywordRelation
      include MachineChair::Modules::KeywordRelation

      def initialize(article, keyword)
        @article = article
        @keyword = keyword
      end
    end
  end
end
