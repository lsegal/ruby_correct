# @requires n >= 0
# @ensures $result == n * fact(n-1) if n > 0
# @ensures $result == 1 if n == 0
# @param [Fixnum] n
# @return [Fixnum]
def fact(n)
  if n > 0
    return n * fact(n-1)
  else
    return 2
  end
end
