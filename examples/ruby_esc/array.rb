# @local [Array<Fixnum>] x
def array_test
  x = []
  assert x.size == 0
  assert x[0] == nil
  x.push 1
  assert x.size == 1
  assert x[0] == 1
  assert x[1] == nil
  x.pop
  assert x.size == 0
end

def array_test2
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
  assert x[2].nil?
  assert x[1] == 2
  assert x[0] == 1
  assert x.pop == 2
  assert x.pop == 1
  assert x.pop == nil
  assert x.pop == nil
  assert x.pop == nil
  assert x.pop == nil
  assert x.pop == nil
  assert x.size == 0
  assert x.size == -3
end

def array_test3
 x = [1,2,3]
 assert x[0] == 1
 assert x[1] == 2
 assert x[2] == 3
end