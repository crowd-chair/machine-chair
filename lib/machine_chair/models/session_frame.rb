module MachineChair
  module Models
    class SessionFrame
      include MachineChair::Modules::SessionFrame

      def initialize(frames = {})
        @frames = frames
      end
    end
  end
end
