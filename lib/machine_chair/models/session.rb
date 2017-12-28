module MachineChair
  module Models
    class Session
      using MachineChair::Extensions
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
        @articles += articles
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

      def save(file_path)
        File.open("#{file_path}/Session_#{Time.now}.dat", "w") do |file|
          pr = @parameter
          point = @session_groups.map{|g| g.score.point}.sum

          file.puts "Session Result: #{Time.now}"
          file.puts "Session Point: #{point}"
          file.puts "Parameter: {Difficulty:#{pr.difficulty}, Priority:#{pr.priority}, Quality:#{pr.quality}}"
          file.puts "Remained Articles: #{remained_articles.size}"
          counter = Hash.new
          @session_groups.each do |group|
            session_name = group.session_name
            counter[session_name.hash] = 0 unless counter[session_name.hash]
            counter[session_name.hash] += 1
            count = counter[session_name.hash]
            difficulty = group.score.difficulty
            priority = group.score.priority
            quality = group.score.quality
            score = group.score.calc(@parameter)

            file.puts "----#{group.session_name.name} (#{count})----"
            file.puts "Score: #{score} => {Difficulty:#{difficulty}, Priority:#{priority}, Quality:#{quality}}"
            group.articles.each do |article|
              file.puts "Name: #{article.name}"
            end
          end
          
          file.puts "----Remained Articles----"
          remained_articles.each do |article|
            file.puts "Name: #{article.name}"
          end
        end
      end
    end
  end
end
