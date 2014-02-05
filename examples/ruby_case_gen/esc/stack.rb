class Stack
  def initialize
    @size = 0
    @elements = []
  end

  # @param [Object] element
  def push(element)
    @size = @size + 1
    @elements.push element
  end

  # @requires @size > 0
  def pop
    @size = @size - 1
    @elements.pop
  end
end

def use
  stack = Stack.new
  stack.pop
end
