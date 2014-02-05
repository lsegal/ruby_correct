class Base
  # @return [Fixnum]
  # @ensures $result == 5
  # @pure
  def foo
    return 5
  end
end

class A < Base
  # @return [Fixnum]
  # @ensures $result == 10
  # @pure
  def foo
    return 10
  end
end

class B < A
  # @param [Base] object
  # @return [Fixnum]
  # @ensures $result == object.foo
  # @pure
  def bar(object)
    return object.foo
  end
end

# @local [B] b
# @local [A] a
# @local [Base] base
def main
  b = B.new
  a = A.new
  base = Base.new
  assert b.bar(a) == 10
  assert b.bar(base) == 5
end
