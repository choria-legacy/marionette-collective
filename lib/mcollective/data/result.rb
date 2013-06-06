module MCollective
  module Data
    class Result
      # remove some methods that might clash with commonly
      # used return data to improve the effectiveness of the
      # method_missing lookup strategy
      undef :type if method_defined?(:type)

      def initialize(outputs)
        @data = {}

        outputs.keys.each do |output|
          @data[output] = Marshal.load(Marshal.dump(outputs[output].fetch(:default, nil)))
        end
      end

      def include?(key)
        @data.include?(key.to_sym)
      end

      def [](key)
        @data[key.to_sym]
      end

      def []=(key, val)
        raise "Can only store String, Integer, Float or Boolean data but got #{val.class} for key #{key}" unless [String, Fixnum, Bignum, Float, TrueClass, FalseClass].include?(val.class)

        @data[key.to_sym] = val
      end

      def keys
        @data.keys
      end

      def method_missing(method, *args)
        key = method.to_sym

        raise NoMethodError, "undefined local variable or method `%s'" % key unless include?(key)

        @data[key]
      end
    end
  end
end
