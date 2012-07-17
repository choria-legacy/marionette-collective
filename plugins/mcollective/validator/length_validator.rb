module MCollective
  module Validator
    class LengthValidator
      def self.validate(validator, length)
        if (validator.size > length) && (length > 0)
          raise ValidatorError, "Input string is longer than #{length} character(s)"
        end
      end
    end
  end
end
