module MCollective
  module Validator
    class RegexValidator
      def self.validate(validator, regex)
        raise ValidatorError, "value should match #{regex}" unless validator.match(regex)
      end
    end
  end
end
