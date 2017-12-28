module MachineChair
  module Models
    class Bidding
      include MachineChair::Modules::Bidding

      def initialize(session_name, article, weight = 1.0)
        @article = article
        @session_name = session_name
        @weight = weight
      end
    end
  end
end
