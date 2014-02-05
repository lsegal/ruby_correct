class A
  # @raise [Exception]
  def foo
    raise Exception
  end
end

# @ivar [Fixnum] counter
class B
  # @local [A] a
  # @modifies @counter
  def main
    @counter = 0
    call1
    assert @counter == 2
  end
  
  # @ensures @counter == old(@counter) + 2
  # @modifies @counter
  def call1
    call2
    @counter += 1
  end

  # @ensures @counter == old(@counter) + 1
  # @modifies @counter
  def call2
    @counter += 1
  end
end