module MachineChair
  module Models
    class Base
      attr_accessor :id

      def initialize(id)
        @id = id
      end

      def ==(base)
        @id == base.id
      end

      def hash
        "#{self.class.name}-#{@id.hash}".hash
      end

      def eql?(other)
        self == other
      end
    end
  end
end
