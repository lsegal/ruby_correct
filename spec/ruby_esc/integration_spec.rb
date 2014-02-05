require_relative 'spec_helper'

describe 'Integration' do
  wrap "def main\n${yield}\nend\n" do
    # Boolean tests
    valid "assert true"
    valid "assert !!true"
    valid "assert !false"
    valid "assert !nil"
    invalid "assert false"

    # Numeric tests
    valid "x = 0; assert x == 3 * 4 - 12"
    valid "x = 1; x += 1; assert x == 2"
    valid "assert 10.abs == 10"
    valid "assert -10.abs == 10"
    valid "assert((5 - 6).abs == 1)"
    invalid "x = 0; assert x + 2 == 3", "assert x + 2 == 3"

    # Literal tests
    valid "x = ''; y = 1; z = [1,2,3]"

    # Loop tests
    valid <<-eof
      j = 9; i = 0
      # @invariant j + i == 9
      while i < 9
        j = 9 - i
      end
    eof
    invalid(<<-eof, "@invariant j + i == 8")
      j = 9; i = 0
      # @invariant j + i == 8
      while i < 9
        j = 9 - i
      end
    eof
  end

  # Math tests
  invalid ex('math')
  
  # Condition testing
  valid ex('condition')

  # Operator tests
  valid ex('operators')

  # Closure tests
  valid ex('closures')

  # Dispatch tests
  valid ex('dispatch_lookup')
  valid ex('dynamic_dispatch')

  # Class method support
  valid ex('class_methods')

  # Object/field tests
  invalid ex('stack'), '@requires @size > 0'

  # Exception tests
  valid ex('exception')
 
  # Contract tests
  valid ex('contracts')
end