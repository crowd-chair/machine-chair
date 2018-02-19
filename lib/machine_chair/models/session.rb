require 'json'

module MachineChair
  module Models
    class Session
      using MachineChair::Extensions
      attr_accessor :session_groups, :remained_articles, :parameter

      def initialize(session_groups = [], parameter: nil)
        @session_group_counter = Hash.new
        @session_slot_counter = Hash.new

        @session_groups = session_groups
        @remained_articles = []
        @parameter = parameter
      end

      def append(session_group)
        @session_groups << session_group
        @session_group_counter[session_group.session_name.hash] ||= 0
        @session_group_counter[session_group.session_name.hash] += 1

        @session_slot_counter[session_group.articles.size] ||= 0
        @session_slot_counter[session_group.articles.size] += 1
      end

      def count_max_session_name
        @session_group_counter.values.max
      end

      def count_groups_with_slot(slot)
        @session_slot_counter[slot] || 0
      end

      def count_session_name(session_name)
        @session_group_counter[session_name.hash] || 0
      end

      # セッションの評価を行う
      # セッション名の分散値が低く，グループのQualityの平均が高いと良い
      def calc_point
        [calc_priority_point, calc_quality_point].mean
      end

      def calc_quality_point
        scores = @session_groups.map{|g| g.score}.compact
        scores.map{|score| score.quality}.mean
      end

      # [NOTE]
      # 分散よりもpriorityが高い方が分かりやすい
      def calc_priority_point
        scores = @session_groups.map{|g| g.score}.compact
        scores.map{|score| score.priority}.mean
      end

      # [TODO]
      # Priorityの正規化がこの式で良いかは要検討
      # 分散が0のときに1, 分散が最大(max_count?)のとき0になるように正規化
      # def calc_priority_point
      #   session_names = @session_groups.map{|g| g.session_name}.uniq
      #   session_names_sd = session_names.map{|n| count_session_name(n)}.sd
      #   max_count = count_max_session_name
      #   (max_count - session_names_sd) / max_count.to_f
      # end

      def eval
        calc_point
      end

      def to_json(tag: "")
        articles = @session_groups.map{|g| g.articles}.flatten + @remained_articles
        keywords = articles.map{|article| article.keywords}.flatten.uniq
        session_names = @session_groups.map{|g| g.session_name}.uniq
        sessions = @session_groups
        parameter = @parameter
        point = calc_point
        quality_point = calc_quality_point
        priority_point = calc_priority_point
        max_count_session = session_names.max_by{|name| @session_group_counter[name.hash]}

        _session_counter = {}

        {
          tag: tag,
          # articles: articles.map{ |article|
          #   {
          #     id: article.id,
          #     name: article.name,
          #     # keywords: article.keywords.map{|keyword| keyword.id}
          #   }
          # },
          # session_names: session_names.map { |session_name|
          #   {
          #     id: session_name.id,
          #     name: session_name.name
          #   }
          # },
          # keywords: keywords.map{|keyword|
          #   {
          #     id: keyword.id,
          #     name: keyword.name
          #   }
          # },
          sessions: sessions.map { |group|
            _session_counter[group.session_name.hash] ||= 0
            _session_counter[group.session_name.hash] += 1
            count = _session_counter[group.session_name.hash]

            {
              session_name: group.session_name.id,
              articles: group.articles.map{|article| article.id},
              count: count
            }
          },
          eval: {
            point: point,
            priority_point: priority_point,
            quality_point: quality_point,
            max_session: {
              session_name: max_count_session.id,
              count: count_max_session_name
            }
          }
        }.to_json
      end

      def save(file_path: nil, file_name: nil)
        file_name = "Session_#{Time.now}.dat" if file_name.nil?
        psth = [file_path, file_name].compact.join("/")
        File.open(psth, "w") do |file|
          pr             = @parameter
          point          = pretty calc_point
          point_quality  = pretty calc_quality_point
          point_priority = pretty calc_priority_point
          dif            = pretty @parameter.difficulty
          pri            = pretty @parameter.priority
          qua            = pretty @parameter.quality

          file.puts "Session Result: #{Time.now}"
          file.puts "Parameter: {Difficulty:#{dif}, Priority:#{pri}, Quality:#{qua}}"
          file.puts "Session Point: #{point} (Priority: #{point_priority}, Quality: #{point_quality})"
          file.puts "Remained Articles: #{@remained_articles.size}"

          counter = Hash.new
          @session_groups.each do |group|
            session_name = group.session_name
            counter[session_name.hash] = 0 unless counter[session_name.hash]
            counter[session_name.hash] += 1
            count = counter[session_name.hash]

            file.puts "----#{group.session_name.name} (#{count})----"

            if(group.score)
              dif = pretty group.score.difficulty
              pri = pretty group.score.priority
              qua = pretty group.score.quality
              score = pretty group.score.calc(@parameter)
              file.puts "Score: #{score} => {Difficulty:#{dif}, Priority:#{pri}, Quality:#{qua}}"
            end
            seed = group.seed
            if seed.nil?
              group.articles.each do |article|
                file.puts "Name: #{article.name}"
              end
            else
              group.articles.each do |article|
                if article == seed
                  file.puts "*Name: #{article.name}"
                else
                  file.puts "Name: #{article.name}"
                end
              end
            end
          end

          if @remained_articles.size > 0
            file.puts "----Remained Articles----"
            @remained_articles.each do |article|
              file.puts "Name: #{article.name}"
            end
          end
        end
      end

      private

      def pretty(f)
        sprintf("%.3f", f)
      end

    end
  end
end
