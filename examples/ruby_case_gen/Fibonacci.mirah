import org.sireum.kiasan.profile.jvm.extension.Kernel as KiasanKernel__
class Fibonacci
  # @param [Fixnum] n
  # @return [Fixnum]
  # @requires n >= 0
  def fib(n:int):int
    KiasanKernel__.assumeTrue(n >= 0)
    if n < 2
      n
    else
      fib(n - 1) + fib(n - 2)
    end
  end
end
