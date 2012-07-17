module MCollective
  module Validator
    class Ipv6addressValidator
      require 'ipaddr'

      def self.validate(validator)
        begin
          ip = IPAddr.new(validator)
          raise ValidatorError, "value should be an ipv6 adddress" unless ip.ipv6?
        rescue
          raise ValidatorError, "value should be an ipv6 address"
        end
      end
    end
  end
end
