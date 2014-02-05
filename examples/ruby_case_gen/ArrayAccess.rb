class ArrayAccess
  def initialize
    @elements = [nil] * 4
    @elements[0] = "A"
    @elements[1] = "B"
    @elements[2] = "C"
    @elements[3] = "D"
  end
  attr_accessor :elements

  # @param [Fixnum] n
  # @return [void]
  def element(n)
    @elements[n] = "Z"
  end
end