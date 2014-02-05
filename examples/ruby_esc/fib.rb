# @requires n >= 0
# @ensures $result == fib(n-1) + fib(n-2) if n >= 2
# @ensures $result == n if n < 2
# @param [Fixnum] n
# @return [Fixnum]
def fib(n)
  n < 2 ? n : fib(n-1) + fib(n-3)
end
