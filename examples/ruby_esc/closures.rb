# @param [Fixnum] n
def add(n)
  yield(n + 3)
end

def main
  x = 1
  # @ensures x == old(x) + y
  add(2) do |y|
    x += y
  end
  assert x == 6
end
