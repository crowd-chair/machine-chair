# [TODO]
# MachineChairモジュール内のみでだけArray拡張を使いたい
class Array
  def sum
    inject(:+)
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

  def normalize
    m = mean
    s = sd
    return self if s == 0
    map { |a| (a - m) / s }
  end
end
