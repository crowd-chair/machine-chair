module MachineChair
  module Models
    class SessionName
      include MachineChair::Modules::SessionName

      def initialize(id, name = nil)
        @id = id
        @name = name
      end
    end
  end
end
