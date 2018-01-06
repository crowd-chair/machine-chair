module MachineChair
  module Models
    class KeywordRelation
      attr_reader :article, :keyword
    
      def initialize(article, keyword)
        @article = article
        @keyword = keyword
      end

      def ==(other)
        @article == other.article && @keyword == other.keyword
      end

      def eql?
        @article == other.article && @keyword == other.keyword
      end

      def hash
        [@article.id, @keyword.id].hash
      end
    end
  end
end
