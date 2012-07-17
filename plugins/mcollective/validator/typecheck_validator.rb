module MCollective
  module Validator
    class TypecheckValidator
      def self.validate(validator, validation_type)
        raise ValidatorError, "value should be a #{validation_type.to_s}" unless check_type(validator, validation_type)
      end

      def self.check_type(validator, validation_type)
        case validation_type
          when Class
            validator.is_a?(validation_type)
          when :integer
            validator.is_a?(Fixnum)
          when :float
            validator.is_a?(Float)
          when :number
            validator.is_a?(Numeric)
          when :string
            validator.is_a?(String)
          when :boolean
            [TrueClass, FalseClass].include?(validator.class)
          else
            false
        end
      end
    end
  end
end
