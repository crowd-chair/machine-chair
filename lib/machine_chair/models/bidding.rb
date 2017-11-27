require "machine_chair/models/base"

module MachineChair
  module Models
    class Bidding < MachineChair::Models::Base
      attr_accessor :article, :session, :tie_strength

      DEFAULT_STRENGTH = 0.5

      def initialize(article, session, tie_strength = 0.5)
        @article = article
        @session = session
        @tie_strength = tie_strength
      end

      def ==(bidding)
        @article == bidding.article && @session == bidding.session
      end

      def hash
        "#{@article.hash}-#{@session.hash}".hash
      end

    end
  end
end
