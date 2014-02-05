class Tak
  # @param [Fixnum] x
  # @param [Fixnum] y
  # @param [Fixnum] z
  # @return [Fixnum]
  def tak(x, y, z)
    unless y < x
      z
    else
      tak( tak(x-1, y, z),
           tak(y-1, z, x),
           tak(z-1, x, y))
    end
  end

  # @return [void]
  def use()
    i = 0
    while i<1000
      tak(24, 16, 8)
      i+=1
    end
  end
end
