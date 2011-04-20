unless Object.respond_to?("instance_variable_defined?")
    class Object
        def instance_variable_defined?(meth)
            instance_variables.include?(meth)
        end
    end
end
