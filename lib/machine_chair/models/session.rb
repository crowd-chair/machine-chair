module MachineChair
  module Models
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
