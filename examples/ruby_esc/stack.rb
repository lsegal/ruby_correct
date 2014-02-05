# @ivar [Fixnum] size
# @ivar [Array<Fixnum>] elements
class Stack
  # @ensures @size == 0
  def initialize
    @size = 0
    @elements = []
  end

  # @ensures @size == old(@size) + 1
  def push(element)
    @size = @size + 1
    @elements.push element
  end

  # @requires @size > 0
  # @ensures @size == old(@size) - 1
  def pop
    @size = @size - 1
    @elements.pop
  end
end

# @local [Stack] stack
def use
  stack = Stack.new
  stack.pop
end
