class ArrayTest
  def array_test
    x = int[0]
    assert x.size == 0
    assert x[0] == 0
    assert x.size == 1
    assert x[0] == 1
    assert x[1] == 0
    assert x.size == 0
    x = []
    assert x.size == 0
    x.push 1
    assert x[0] == 1
    assert x.size == 1
    x.push 2
    assert x[0] == 1
    assert x.size == 2
    x.push 3
    assert x[0] == 1
    assert x[1] == 2
    assert x[2] == 3
    assert x.size == 3
    assert x.pop == 3
    assert x.size == 2
    assert x[1] == 2
    assert x[0] == 1
    x = [1,2,3]
    assert x[0] == 1
    assert x[1] == 2
    assert x[2] == 3
  end
end
