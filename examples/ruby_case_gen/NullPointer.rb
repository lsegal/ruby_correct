class NullPointer
  # @param [Fixnum] n
  def fuzz(n)
    n % 2 == 0 ? nil : self
  end

  def call; 0 end

  def self.main
    ptr = NullPointer.new
    ptr = NullPointer(ptr.fuzz(1))
    ptr.call
  end
end
