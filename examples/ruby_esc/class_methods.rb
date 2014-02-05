class A
  # @return [A]
  def self.creator
    return new
  end
end

def main
  A.creator
end
