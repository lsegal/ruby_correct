class Math
  # @return [Fixnum]
  # @ensures $result == 100
  def one_hundred; return 100 end

  # @return [Fixnum]
  # @ensures $result == one_hundred + 100
  def two_hundred; return 200 end
end

