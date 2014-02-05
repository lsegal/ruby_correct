class DivideByZeroException < Exception
end

class Div0
  # @param [Fixnum] n
  # @return [Fixnum]
  # @ensures $exception != nil if n == 0
  # @ensures $result == 10 / n if n != 0
  # @raise [DivideByZeroException]
  def ten_div_by(n)
    raise DivideByZeroException if n == 0
    return 10 / n
  end
end

class Main
  # @return [Fixnum]
  # @local [Div0] div
  # @ensures $result == 0
  def try_div0
    div = Div0.new
    div.ten_div_by(0)
    return 1
  rescue
    return 0
  end
end
