module MachineChair
  module Models
    class Group
      attr_accessor :session, :articles

      def initialize(session, articles)
        @session = session
        @articles = articles
      end

      def slot
        @articles.size
      end
    end
  end
end
