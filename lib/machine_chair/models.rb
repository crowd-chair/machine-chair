require "machine_chair/modules"

module MachineChair
  module Models
    class Article
      include MachineChair::Modules::Article

      def initialize(id, name = nil)
        @id = id
        @name = name
      end
    end

    class SessionName
      include MachineChair::Modules::SessionName

      def initialize(id, name = nil)
        @id = id
        @name = name
      end
    end

    class Keyword
      include MachineChair::Modules::Keyword

      def initialize(id, name = nil)
        @id = id
        @name = name
      end
    end

    class Bidding
      include MachineChair::Modules::Bidding

      def initialize(id, article, session_name, weight)
        @id = id
        @article = article
        @session_name = session_name
        @weight = weight
      end
    end

    class SessionFrame
      include MachineChair::Modules::SessionFrame

      def initialize(frames)
        @frames = frames
      end
    end

    class SessionGroup
      include MachineChair::Modules::SessionGroup

      def initialize(session_name, articles)
        @session_name = session_name
        @articles = articles
      end
    end
  end
end
