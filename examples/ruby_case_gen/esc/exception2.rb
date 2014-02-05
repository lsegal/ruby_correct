class A
  def foo
    raise Exception
  end
end

class B
  def main
    @counter = 0
    call1
    assert @counter == 2
  end
  
  def call1
    call2
    @counter += 1
  end

  def call2
    @counter += 1
  end
end