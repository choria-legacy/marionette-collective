# Make arrays of Symbols sortable
class Symbol
  include Comparable

  def <=>(other)
    self.to_s <=> other.to_s
  end unless method_defined?("<=>")
end

# a method # that walks an array in groups, pass a block to
# call the block on each sub array
class Array
  def in_groups_of(chunk_size, padded_with=nil)
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
      result.each{|a| yield(a)}
    else
      result
    end
  end unless method_defined?(:in_groups_of)
end

