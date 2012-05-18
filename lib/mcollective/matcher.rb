module MCollective
  # A parser and scanner that creates a stack machine for a simple
  # fact and class matching language used on the CLI to facilitate
  # a rich discovery language
  #
  # Language EBNF
  #
  # compound = ["("] expression [")"] {["("] expression [")"]}
  # expression = [!|not]statement ["and"|"or"] [!|not] statement
  # char = A-Z | a-z | < | > | => | =< | _ | - |* | / { A-Z | a-z | < | > | => | =< | _ | - | * | / | }
  # int = 0|1|2|3|4|5|6|7|8|9{|0|1|2|3|4|5|6|7|8|9|0}
  module Matcher
    autoload :Parser, "mcollective/matcher/parser"
    autoload :Scanner, "mcollective/matcher/scanner"

    # Helper creates a hash from a function call string
    def self.create_function_hash(function_call)
      func_hash = {}
      f = ""
      func_parts = function_call.split(/(!=|>=|<=|<|>|=)/)
      func_hash["r_compare"] = func_parts.pop
      func_hash["operator"] = func_parts.pop
      func = func_parts.join

      # Deal with dots in function parameters and functions without dot values
      if func.match(/^.+\(.*\)$/)
        f = func
      else
        func_parts = func.split(".")
        func_hash["value"] = func_parts.pop
        f = func_parts.join(".")
      end

      # Deal with regular expression matches
      if func_hash["r_compare"] =~ /^\/.*\/$/
        func_hash["operator"] = "=~" if func_hash["operator"] == "="
        func_hash["operator"] = "!=~" if func_hash["operator"] == "!="
        func_hash["r_compare"] = Regexp.new(func_hash["r_compare"].gsub(/^\/|\/$/, ""))
      # Convert = operators to == so they can be propperly evaluated
      elsif func_hash["operator"] == "="
        func_hash["operator"] = "=="
      end

      # Grab function name and parameters from left compare string
      func_hash["name"], func_hash["params"] = f.split("(")
      if func_hash["params"] == ")"
        func_hash["params"] = nil
      else

        # Walk the function parameters from the front and from the
        # back removing the first and last instances of single of
        # double qoutes. We do this to handle the case where params
        # contain escaped qoutes.
        func_hash["params"] = func_hash["params"].gsub(")", "")
        func_quotes = func_hash["params"].split(/('|")/)

        func_quotes.each_with_index do |item, i|
          if item.match(/'|"/)
            func_quotes.delete_at(i)
            break
          end
        end

        func_quotes.reverse.each_with_index do |item,i|
          if item.match(/'|"/)
            func_quotes.delete_at(func_quotes.size - i - 1)
            break
          end
        end

        func_hash["params"] = func_quotes.join
      end

      func_hash
    end

    # Returns the result of an executed function
    def self.execute_function(function_hash)
      # In the case where a data plugin isn't present there are two ways we can handle
      # the raised exception. The function result can either be false or the entire
      # expression can fail.
      #
      # In the case where we return the result as false it opens us op to unexpected
      # negation behavior.
      #
      #   !foo('bar').name = bar
      #
      # In this case the user would expect discovery to match on all machines where
      # the name value of the foo function does not equal bar. If a non existent function
      # returns false then it is posible to match machines where the name value of the
      # foo function is bar.
      #
      # Instead we raise a DDLValidationError to prevent this unexpected behavior from
      # happening.

      result = Data.send(function_hash["name"], function_hash["params"])

      if function_hash["value"]
        eval_result = result.send(function_hash["value"])
        return eval_result
      else
        return result
      end
    rescue NoMethodError
      Log.debug("cannot execute discovery function '#{function_hash["name"]}'. data plugin not found")
      raise DDLValidationError
    end

    # Evaluates a compound statement
    def self.eval_compound_statement(expression)
      if expression.values.first =~ /^\//
        return Util.has_cf_class?(expression.values.first)
      elsif expression.values.first =~ />=|<=|=|<|>/
        optype = expression.values.first.match(/>=|<=|=|<|>/)
        name, value = expression.values.first.split(optype[0])
        unless value.split("")[0] == "/"
          optype[0] == "=" ? optype = "==" : optype = optype[0]
        else
          optype = "=~"
        end

        return Util.has_fact?(name,value, optype).to_s
      else
        return Util.has_cf_class?(expression.values.first)
      end
    end

    # Returns the result of an evaluated compound statement that
    # includes a function
    def self.eval_compound_fstatement(function_hash)
      l_compare = execute_function(function_hash)

      # Prevent unwanted discovery by limiting comparison operators
      # on Strings and Booleans
      if((l_compare.is_a?(String) || l_compare.is_a?(TrueClass) || l_compare.is_a?(FalseClass)) && function_hash["operator"].match(/<|>/))
        Log.debug "Cannot do > and < comparison on Booleans and Strings '#{l_compare} #{function_hash["operator"]} #{function_hash["r_compare"]}'"
        return false
      end

      # Prevent backticks in function parameters
      if function_hash["params"] =~ /`/
        Log.debug("Cannot use backticks in function parameters")
        return false
      end

      # Escape strings for evaluation
      function_hash["r_compare"] = "\"#{function_hash["r_compare"]}\"" if(l_compare.is_a?(String)  && !(function_hash["operator"] =~ /=~|!=~/))

      # Do a regex comparison if right compare string is a regex
      if function_hash["operator"] =~ /(=~|!=~)/
        # Fail if left compare value isn't a string
        unless l_compare.is_a?(String)
          Log.debug("Cannot do a regex check on a non string value.")
          return false
        else
          compare_result = l_compare.match(function_hash["r_compare"])
          # Flip return value for != operator
          if function_hash["operator"] == "!=~"
            !((compare_result.nil?) ? false : true)
          else
            (compare_result.nil?) ? false : true
          end
        end
        # Otherwise evaluate the logical comparison
      else
        l_compare = "\"#{l_compare}\"" if l_compare.is_a?(String)
        result = eval("#{l_compare} #{function_hash["operator"]} #{function_hash["r_compare"]}")
        (result.nil?) ? false : result
      end
    end

    # Creates a callstack to be evaluated from a compound evaluation string
    def self.create_compound_callstack(call_string)
      callstack = Matcher::Parser.new(call_string).execution_stack
      callstack.each_with_index do |statement, i|
        if statement.keys.first == "fstatement"
          callstack[i]["fstatement"] = create_function_hash(statement.values.first)
        end
      end
      callstack
    end
  end
end
