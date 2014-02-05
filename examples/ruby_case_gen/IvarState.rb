class IvarState
  # @param [Fixnum] x
  def initialize(x)
    @foo = x
  end
  
  def setup
    @foo += 1
  end
  
  # @return [Fixnum]
  def finalize_()
    @foo -= 1
  end
  
  # @param [Fixnum] n
  # @return [void]
  def self.main(n)
    ivar = IvarState.new(n)
    ivar.setup if n % 2 == 0
    assert(ivar.finalize_ == n)
  end
end