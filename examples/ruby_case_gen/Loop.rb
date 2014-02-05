class Loop
  # @param [Fixnum] n
  def initialize(n)
    @counter = n
  end
  
  def counter; @counter end

  def loop()
    [1,2,3].each {|i| @counter += i }
  end
  
  # @param [Fixnum] n
  def self.main(n)
    looper = Loop.new(n)
    looper.loop
    10 / looper.counter
  end
end
