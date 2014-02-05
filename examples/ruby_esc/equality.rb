def equality_test; assert !false end
def equality_test2; assert !true end

# @local [Boolean] x
def equality_test3
  x = !true
  assert x
end

def equality_test4
  assert true == !true
end
