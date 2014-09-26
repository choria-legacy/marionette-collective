# start_with? was introduced in 1.8.7, we need to support
# 1.8.5 and 1.8.6
class String
  def start_with?(str)
    return self[0..(str.length-1)] == str
  end unless method_defined?("start_with?")
end

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

class String
  def bytes(&block)
    # This should not be necessary, really ...
    require 'enumerator'
    return to_enum(:each_byte) unless block_given?
    each_byte(&block)
  end unless method_defined?(:bytes)
end

class Dir
  def self.mktmpdir(prefix_suffix=nil, tmpdir=nil)
    case prefix_suffix
    when nil
      prefix = "d"
      suffix = ""
    when String
      prefix = prefix_suffix
      suffix = ""
    when Array
      prefix = prefix_suffix[0]
      suffix = prefix_suffix[1]
    else
      raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
    end
    tmpdir ||= Dir.tmpdir
    t = Time.now.strftime("%Y%m%d")
    n = nil
    begin
      path = "#{tmpdir}/#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
      path << "-#{n}" if n
      path << suffix
      Dir.mkdir(path, 0700)
    rescue Errno::EEXIST
      n ||= 0
      n += 1
      retry
    end

    if block_given?
      begin
        yield path
      ensure
        FileUtils.remove_entry_secure path
      end
    else
      path
    end
  end unless method_defined?(:mktmpdir)

  def self.tmpdir
    tmp = '.'
    for dir in [ENV['TMPDIR'], ENV['TMP'], ENV['TEMP'], '/tmp']
      if dir and stat = File.stat(dir) and stat.directory? and stat.writable?
        tmp = dir
        break
      end rescue nil
    end
    File.expand_path(tmp)
  end unless method_defined?(:tmpdir)
end

# Reject all SSLv2 ciphers and all SSLv2 or SSLv3 handshakes by default
require 'openssl'
class OpenSSL::SSL::SSLContext
  if DEFAULT_PARAMS[:options]
    DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_NO_SSLv2 | OpenSSL::SSL::OP_NO_SSLv3
  else
    DEFAULT_PARAMS[:options] = OpenSSL::SSL::OP_NO_SSLv2 | OpenSSL::SSL::OP_NO_SSLv3
  end

  # ruby 1.8.5 doesn't define this constant, but has it on by default
  if defined?(OpenSSL::SSL::OP_DONT_INSERT_EMPTY_FRAGMENTS)
    DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_DONT_INSERT_EMPTY_FRAGMENTS
  end

  DEFAULT_PARAMS[:ciphers] << ':!SSLv2'

  alias __mcollective_original_initialize initialize
  private :__mcollective_original_initialize

  def initialize(*args)
    __mcollective_original_initialize(*args)
    params = {
      :options => DEFAULT_PARAMS[:options],
      :ciphers => DEFAULT_PARAMS[:ciphers],
    }
    set_params(params)
  end
end
