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

      def initialize(session_name, article, weight = 1.0)
        @article = article
        @session_name = session_name
        @weight = weight
      end
    end

    class SessionFrame
      include MachineChair::Modules::SessionFrame

      def initialize(frames = {})
        @frames = frames
      end
    end

    class SessionGroup
      include MachineChair::Modules::SessionGroup

      def initialize(session_name, articles, score: nil)
        @session_name = session_name
        @articles = articles
        @score = score
      end
    end

    class Score
      attr_reader :difficulty, :priority, :quality

      def initialize(difficulty: 0.0, priority: 0.0, quality: 0.0)
        @difficulty = difficulty
        @priority = priority
        @quality = quality
      end

      def calc(param)
        @difficulty * param.difficulty + @priority * param.priority + @quality * param.quality
      end
    end

    class Parameter
      attr_reader :difficulty, :priority, :quality

      def initialize(difficulty: 0.0, priority: 0.0, quality: 0.0)
        @difficulty = difficulty
        @priority = priority
        @quality = quality
        @difficulty = 1.0 - priority - quality unless difficulty
        normalize!
      end

      def normalize!
        norm = @difficulty + @priority + @quality
        @difficulty /= norm
        @priority /= norm
        @quality /= norm
      end
    end

    class Session
      attr_accessor :session_groups, :articles, :parameter, :session_frame

      def initialize(session_groups = [], articles = [], session_frame = nil, parameter: nil)
        @session_group_counter = Hash.new
        @session_groups = session_groups
        @articles = articles
        @session_frame = session_frame
        @parameter = parameter
      end

      def append(session_group)
        @session_groups << session_group
        @session_group_counter[session_group.session_name.hash] ||= 0
        @session_group_counter[session_group.session_name.hash] += 1
      end

      def append_remained_articles(articles)
        @articles << articles
      end

      def remained_articles
        @articles
      end

      def remained_session_frame
        @session_frame
      end

      def compare(session)
        all_bidding = session.session_groups.map{|g| g.articles.map{|a| Bidding.new(g.session_name, a)}}.flatten
        my_bidding = self.session_groups.map{|g| g.articles.map{|a| Bidding.new(g.session_name, a)}}.flatten

        all = all_bidding.size
        correct = all_bidding.select{|b| my_bidding.include? b}.size

        puts "Recall: #{correct.to_f/all.to_f}, All: #{all}, Correct: #{correct}"
        puts "Max Session Count: (#{@session_group_counter.values.max})"
        puts "Remained Article Size: #{remained_articles.size}"
      end
    end
  end
end
