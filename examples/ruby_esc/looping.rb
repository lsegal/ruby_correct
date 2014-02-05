def loop
  j = 9
  i = 0
  # @invariant j + i == 9
  while i < 9
    j = 9 - i
  end
end

# @local [Fixnum] counter
def loop2
  counter = 0
  # @local [Fixnum] x
  [1,2,3].each {|x| counter += x }
  assert counter == 6
end

def loop3
  counter = 0
  # @local [Fixnum] v
   [1,2,3].each_with_index {|x,v| counter += v }
  assert counter == 3
end
