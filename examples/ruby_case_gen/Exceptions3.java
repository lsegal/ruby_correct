// Generated from Exceptions3.mirah
public class Exceptions3 extends java.lang.Object {
  public void main(java.lang.String arg) {
    Exceptions3 e = null;
    e = new Exceptions3();
    e.passcheck(arg);
  }
  public boolean passcheck(java.lang.String arg) {
    if ((arg.length() < 4)) {
      throw new java.lang.RuntimeException("Invalid password!");
    }
    return (arg == "password") ? (true) : (false);
  }
}
