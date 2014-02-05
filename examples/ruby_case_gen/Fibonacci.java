// Generated from Fibonacci.mirah
public class Fibonacci extends java.lang.Object {
  public int fib(int n) {
    org.sireum.kiasan.profile.jvm.extension.Kernel.assumeTrue((n >= 0));
    return (n < 2) ? (n) : ((this.fib((n - 1)) + this.fib((n - 2))));
  }
}
