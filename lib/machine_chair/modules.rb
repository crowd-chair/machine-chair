module MachineChair
  module Modules
    module Base
      attr_accessor :id, :name

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

    module Article
      include Base
    end

    module SessionName
      include Base
    end

    module Keyword
      include Base
    end

    module KeywordRelation
      attr_accessor :article, :keyword

      def ==(other)
        @article == other.article && @keyword == other.keyword
      end

      def eql?
        @article == other.article && @keyword == other.keyword
      end

      def hash
        [@article.id, @keyword.id].hash
      end
    end

    module Bidding
      attr_accessor :article, :session_name, :weight

      def ==(other)
        @article == other.article && @session_name == other.session_name
      end

      def eql?(other)
        @article == other.article && @session_name == other.session_name
      end

      def hash
        [@article.id, @session_name.id].hash
      end
    end

    module SessionFrame
      attr_accessor :frames

      def available?(slot)
        @frames[slot] && @frames[slot] > 0
      end

      def max
        _min = @frames.keys.min
        _max = @frames.keys.max
        _max.downto(_min).each do |slot|
          return slot if available?(slot)
        end
        0
      end

      def min
        _min = @frames.keys.min
        _max = @frames.keys.max
        _min.upto(_max).each do |slot|
          return slot if available?(slot)
        end
        0
      end

      def update!(session_group)
        raise "No Available Frame" unless available? session_group.slot
        @frames[session_group.slot] -= 1
      end
    end

    module SessionGroup
      attr_accessor :session_name, :articles

      def slot
        articles.size
      end
    end
  end
end
