class Looping
  def loop
    j = 9
    i = 0
    while i < 9
      j = 9 - i
    end
  end

  def loop2
    counter = 0
    [1,2,3].each {|x| counter += x }
    assert counter == 6
  end

  def loop3
    counter = 0
     [1,2,3].each_with_index {|x,v| counter += v }
    assert counter == 3
  end
end
