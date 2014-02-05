import 'java.util.HashMap'
import 'java.util.Map'
import 'java.util.ArrayList'
import 'org.sireum.kiasan.profile.jvm.substitution.ISubstitutionProvider'

class SimpleStub
  def initialize(x:int); end
end

class SubstitutionProvider
  implements ISubstitutionProvider

  def getClassSubstitutionMap():Map
    map = HashMap.new
    map.put(ArrayIndexOutOfBoundsException.class, SimpleStub.class)
    map.put(ArrayList.class, SimpleStub.class)
    map
  end

  def getMethodSubstitutionMap():Map
    HashMap.new
  end
end