# @param [Fixnum] n
def add(n)
  yield(n + 3)
end

def main
  x = 1
  add(2) do |y|
    x += y
  end
  assert x == 6
end
