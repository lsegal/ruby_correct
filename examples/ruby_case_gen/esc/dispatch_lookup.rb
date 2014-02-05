class A
  # @param [Fixnum] n
  def five(n)
    return n + 5
  end
end

class B < A
  def run
    return self.five(5)
  end
end

class C < B; end

class D
  # @param [C] c
  def run_all(c)
    assert c.run == 10
  end
end

def main
  D.new.run_all(C.new)
end