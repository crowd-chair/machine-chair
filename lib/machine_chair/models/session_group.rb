module MachineChair
  module Models
    class SessionGroup
      include MachineChair::Modules::SessionGroup

      def initialize(session_name, articles, score: nil)
        @session_name = session_name
        @articles = articles
        @score = score
      end
    end
  end
end
