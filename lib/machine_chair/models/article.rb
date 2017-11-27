require "machine_chair/models/base"

module MachineChair
  module Models
    class Article < MachineChair::Models::Base
      attr_accessor :id, :name

      def initialize(id, name)
        @id = id
        @name = name
      end
    end
  end
end
