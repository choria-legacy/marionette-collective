module MCollective
  module Validator
    class ArrayValidator
      def self.validate(validator, array)
        raise ValidatorError, "value should be one of %s" % [ array.join(", ") ] unless array.include?(validator)
      end
    end
  end
end
