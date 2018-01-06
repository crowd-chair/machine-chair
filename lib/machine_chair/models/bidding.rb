module MachineChair
  module Models
    class Bidding
      attr_reader :article, :session_name, :weight

      def initialize(session_name, article, weight = 1.0)
        @article = article
        @session_name = session_name
        @weight = weight
      end

      def ==(other)
        @article == other.article && @session_name == other.session_name
      end

      def eql?(other)
        @article == other.article && @session_name == other.session_name
      end

      def hash
        [@article.id, @session_name.id].hash
      end
    end
  end
end
