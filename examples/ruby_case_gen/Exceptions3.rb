class Exceptions3
  # @param [String] arg
  # @return [void]
  def main(arg)
    e = Exceptions3.new
    e.passcheck(arg)
  end

  # @param [String] arg
  # @return [boolean]
  def passcheck(arg)
    raise "Invalid password!" if arg.length < 4
    arg == "password" ? true : false
  end
end
