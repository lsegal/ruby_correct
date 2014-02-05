# @core
class Object
  # @return [self]
  # @ensures "$result != $nil"
  def self.new
    object = allocate
    object.initialize
    return object
  end

  # @return [self]
  # @ensures "$result != $nil"
  def self.allocate; end

  def initialize; end

  # @param [Object] other
  # @ensures "self == other ==> $result == $true"
  # @ensures "self != other ==> $result == $false"
  # @return [Boolean]
  # @pure
  def ==(other) end

  # @param [Object] other
  # @ensures "self != other ==> $result == $true"
  # @ensures "self == other ==> $result == $false"
  # @return [Boolean]
  # @pure
  def !=(other) end

  # @ensures "self == $nil ==> $result == $true"
  # @return [Boolean]
  # @pure
  def nil?; end
end

# @core
class Fixnum < Object
  # @param [Fixnum] other
  # @ensures "$result == self + other"
  # @return [Fixnum]
  # @pure
  def +(other) end

  # @param [Fixnum] other
  # @ensures "$result == self - other"
  # @return [Fixnum]
  # @pure
  def -(other) end

  # @param [Fixnum] other
  # @ensures "$result == self * other"
  # @return [Fixnum]
  # @pure
  def *(other) end

  # @param [Fixnum] other
  # @ensures "$result == self / other"
  # @return [Fixnum]
  # @pure
  def /(other) end

  # @param [Fixnum] other
  # @ensures "$result == self % other"
  # @return [Fixnum]
  # @pure
  def %(other) end

  # @param [Fixnum] other
  # @ensures "self < other ==> $result == $true"
  # @ensures "self >= other ==> $result == $false"
  # @return [Boolean]
  # @pure
  def <(other) end

  # @param [Fixnum] other
  # @ensures "self > other ==> $result == $true"
  # @ensures "self <= other ==> $result == $false"
  # @return [Boolean]
  # @pure
  def >(other) end

  # @param [Fixnum] other
  # @ensures "self <= other ==> $result == $true"
  # @ensures "self > other ==> $result == $false"
  # @return [Boolean]
  # @pure
  def <=(other) end
  
  # @param [Fixnum] other
  # @ensures "self >= other ==> $result == $true"
  # @ensures "self < other ==> $result == $false"
  # @return [Boolean]
  # @pure
  def >=(other) end
  
  # @ensures "$result == -self"
  # @return [Fixnum]
  # @pure
  def -@; end

  # @ensures $result == -self if self < 0
  # @ensures $result == self if self >= 0
  # @return [Fixnum]
  # @pure
  def abs; end
  
  # @param [Fixnum] n
  # @requires n >= self
  # @return [Fixnum]
  def upto(n)
    i = self
    # @invariant (i - old(i)).abs <= 1
    while i <= n
      yield(i)
      i += 1
    end
    self
  end
  
  # @param [Fixnum] n
  # @requires n <= self
  # @return [Fixnum]
  def downto(n)
    i = self
    # @invariant (i - old(i)).abs <= 1
    while i >= n
      yield(i)
      i -= 1
    end
    self
  end
end

# @core
class Boolean
  # @ensures "self == $true ==> $result == $false"
  # @ensures "self == $false ==> $result == $true"
  # @return [Boolean]
  # @pure
  def !; end
end

# @core
class TrueClass < Boolean
end

# @core
class FalseClass < Boolean
end

# @core
class Exception < Object; end

# @core
class RuntimeException < Exception; end

# @core
class NilClass
  # @ensures "$result == $true"
  # @pure
  def !; end
end

# @ivar [Array<$T>] elements
# @ivar [Fixnum] size
# @core
class Array < Object
  # @ensures "(forall x:VALUE :: $arrget($heap[self][Array$elements], x) == $nil)"
  # @ensures @size == 0
  # @modifies @size
  # @modifies @elements
  def initialize; end

  # @param [$T] element
  # @ensures "$arrget($heap[self][Array$elements], old($heap[self][Array$size])) == element"
  # @ensures "(forall x:VALUE :: x != old($heap[self][Array$size]) ==> $arrget($heap[self][Array$elements], x) == old($arrget($heap[self][Array$elements], x)))"
  # @ensures @size == old(@size) + 1
  # @modifies @elements
  # @modifies @size
  def push(element) end

  # @ensures @size == old(@size) - 1
  # @ensures "$result == old($arrget($heap[self][Array$elements], $heap[self][Array$size] - 1))"
  # @ensures "$arrget($heap[self][Array$elements], $heap[self][Array$size] - 1) == $nil"
  # @ensures "(forall x:VALUE :: x != $heap[self][Array$size] ==> $arrget($heap[self][Array$elements], x) == old($arrget($heap[self][Array$elements], x)))"
  # @modifies @elements
  # @modifies @size
  # @return [$T]
  def pop; end

  # @param [Fixnum] idx
  # @ensures "$result == $arrget($heap[self][Array$elements], idx)"
  # @ensures $result == nil if idx >= @size
  # @return [$T]
  # @pure
  def [](idx) end

  # @param [Fixnum] idx
  # @param [$T] value
  # @ensures "$arrget($heap[self][Array$elements], idx) == value"
  # @ensures $result == value
  # @ensures "(forall x:VALUE :: x != idx ==> $arrget($heap[self][Array$elements], x) == old($arrget($heap[self][Array$elements], x)))"
  # @ensures @size == idx+1 if idx+1 > @size
  # @modifies @elements
  def []=(idx, value) end

  # @ensures $result == @size
  # @return [Fixnum]
  # @pure
  def size; end

  # @local [Fixnum] i
  def each
    i = 0
    # @invariant i >= 0
    while i < @size
      yield(self[i])
      i += 1
    end
  end

  # @local [Fixnum] i
  def each_with_index
    i = 0
    # @invariant i >= 0
    while i < @size
      yield(self[i], i)
      i += 1
    end
  end
end
