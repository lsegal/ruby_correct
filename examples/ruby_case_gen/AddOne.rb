class AddOne
  # @param [Fixnum] x
  def add_one(x)
    x + 1
  end

  def add()
    x = 0
    add_one(x)
    raise AssertionError if x != 1
  end

  def add_proper()
    x = 0
    x = add_one(x)
    raise AssertionError if x != 1
  end

  # @return [void]
  def self.main()
    AddOne.new.add
  end
end