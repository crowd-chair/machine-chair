module MachineChair
  module Modules
    module Bidding
      attr_reader :article, :session_name, :weight

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
