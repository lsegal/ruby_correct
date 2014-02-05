class Base
  def foo
    return 5
  end
end

class A < Base
  def foo
    return 10
  end
end

class B < A
  # @param [Base] object
  def bar(object)
    return object.foo
  end
end

def main
  b = B.new
  a = A.new
  base = Base.new
  assert b.bar(a) == 10
  assert b.bar(base) == 5
end
