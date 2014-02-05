import org.sireum.kiasan.profile.jvm.extension.Kernel as KiasanKernel__
class Exceptions3
  # @param [String] arg
  # @return [void]
  def main(arg:String):void
    e = Exceptions3.new
    e.passcheck(arg)
  end

  # @param [String] arg
  # @return [boolean]
  def passcheck(arg:String):boolean
    raise "Invalid password!" if arg.length < 4
    arg == "password" ? true : false
  end
end
