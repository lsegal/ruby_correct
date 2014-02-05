class A
  # @param [Fixnum] n
  # @return [Fixnum]
  # @ensures $result == n + 5
  def five(n)
    return n + 5
  end
end

class B < A
  # @ensures $result == 10
  # @return [Fixnum]
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