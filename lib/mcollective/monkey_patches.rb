# Make arrays of Symbols sortable
class Symbol
  include Comparable

  def <=>(other)
    self.to_s <=> other.to_s
  end unless method_defined?("<=>")
end

# This provides an alias for RbConfig to Config for versions of Ruby older then
# # version 1.8.5. This allows us to use RbConfig in place of the older Config in
# # our code and still be compatible with at least Ruby 1.8.1.
# require 'rbconfig'
unless defined? ::RbConfig
  ::RbConfig = ::Config
end

# a method # that walks an array in groups, pass a block to
# call the block on each sub array
class Array
  def in_groups_of(chunk_size, padded_with=nil, &block)
    arr = self.clone

    # how many to add
    padding = chunk_size - (arr.size % chunk_size)

    # pad at the end
    arr.concat([padded_with] * padding) unless padding == chunk_size

    # how many chunks we'll make
    count = arr.size / chunk_size

    # make that many arrays
    result = []
    count.times {|s| result <<  arr[s * chunk_size, chunk_size]}

    if block_given?
      result.each_with_index do |a, i|
        case block.arity
          when 1
            yield(a)
          when 2
            yield(a, (i == result.size - 1))
          else
            raise "Expected 1 or 2 arguments, got #{block.arity}"
        end
      end
    else
      result
    end
  end unless method_defined?(:in_groups_of)
end

