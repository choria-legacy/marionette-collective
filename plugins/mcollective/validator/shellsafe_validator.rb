module MCollective
  module Validator
    class ShellsafeValidator
      def self.validate(validator)
        raise ValidatorError, "value should be a String" unless validator.is_a?(String)

        ['`', '$', ';', '|', '&&', '>', '<'].each do |chr|
          raise ValidatorError, "value should not have #{chr} in it" if validator.match(Regexp.escape(chr))
        end
      end
    end
  end
end
