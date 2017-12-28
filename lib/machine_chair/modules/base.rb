module MachineChair
  module Modules
    module Base
      attr_reader :id, :name

      def ==(other)
        @id == other.id
      end

      def hash
        [@id].hash
      end

      def eql?(other)
        @id == other.id
      end
    end
  end
end
