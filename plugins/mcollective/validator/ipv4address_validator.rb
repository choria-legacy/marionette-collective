module MCollective
  module Validator
    class Ipv4addressValidator
      require 'ipaddr'

      def self.validate(validator)
        begin
          ip = IPAddr.new(validator)
          raise ValidatorError, "value should be an ipv4 adddress" unless ip.ipv4?
        rescue
          raise ValidatorError, "value should be an ipv4 address"
        end
      end
    end
  end
end
