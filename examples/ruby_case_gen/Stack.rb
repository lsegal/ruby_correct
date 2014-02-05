class Stack
  def initialize
    @size = 0
    @elements = Object[10]
  end

  # @param [Object] element
  def push(element)
    @elements[@size] = element
    @size += 1
  end

  def pop
    @size -= 1
    assert @size >= 0
    @elements[@size]
  end
  
  def self.use()
    stack = Stack.new
    stack.push(Integer(1))
    stack.pop
  end
end
