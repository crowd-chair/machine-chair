module MachineChair
  module Extensions
    refine Array do
      def sum
        inject(:+) || 0
      end

      def mean
        sum.to_f / size
      end

      def var
        m = mean
        inject(0) { |a,b| a + (b - m) ** 2 } / (size - 1)
      end

      def sd
        Math.sqrt(var)
      end

      # def normalize
      #   m = mean
      #   s = sd
      #   return self if s == 0
      #   map { |a| (a - m) / s }
      # end

      def normalize
        m = self.max
        return self if m == 0
        map { |a| a / m }
      end
    end

    refine Hash do
      def normalize
        values = self.values
        m = values.mean
        s = values.sd
        return self if s == 0
        Hash[self.map{|k, v| [k, (v - m) / s]}]
      end
    end

    refine Vector do
      def cos(vec)
        self.dot(vec) / (self.norm * vec.norm)
      end
    end
  end
end
