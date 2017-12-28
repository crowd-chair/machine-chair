module MachineChair
  module Modules
    module KeywordRelation
      attr_reader :article, :keyword

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
