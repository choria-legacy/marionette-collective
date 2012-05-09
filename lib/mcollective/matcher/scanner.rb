module MCollective
  module Matcher
    class Scanner
      attr_accessor :arguments, :token_index

      def initialize(arguments)
        @token_index = 0
        @arguments = arguments.split("")
      end

      # Scans the input string and identifies single language tokens
      def get_token
        if @token_index >= @arguments.size
          return nil
        end

        case @arguments[@token_index]
        when "("
          return "(", "("

        when ")"
          return ")", ")"

        when "n"
          if (@arguments[@token_index + 1] == "o") && (@arguments[@token_index + 2] == "t") && ((@arguments[@token_index + 3] == " ") || (@arguments[@token_index + 3] == "("))
            @token_index += 2
            return "not", "not"
          else
            gen_statement
          end

        when "!"
          return "not", "not"

        when "a"
          if (@arguments[@token_index + 1] == "n") && (@arguments[@token_index + 2] == "d") && ((@arguments[@token_index + 3] == " ") || (@arguments[@token_index + 3] == "("))
            @token_index += 2
            return "and", "and"
          else
            gen_statement
          end

        when "o"
          if (@arguments[@token_index + 1] == "r") && ((@arguments[@token_index + 2] == " ") || (@arguments[@token_index + 2] == "("))
            @token_index += 1
            return "or", "or"
          else
            gen_statement
          end

        when " "
          return " ", " "

        else
          gen_statement
        end
      end

      private
      # Helper generates a statement token
      def gen_statement
        func = false
        current_token_value = ""
        j = @token_index

        begin
          if (@arguments[j] == "/")
            begin
              current_token_value << @arguments[j]
              j += 1
            end until (j >= @arguments.size) || (@arguments[j] =~ /\s/)
          elsif (@arguments[j] =~ /=|<|>/)
            while !(@arguments[j] =~ /=|<|>/)
              current_token_value << @arguments[j]
              j += 1
            end

            current_token_value << @arguments[j]
            j += 1

            if @arguments[j] == "/"
              begin
                current_token_value << @arguments[j]
                j += 1
                if @arguments[j] == "/"
                  current_token_value << "/"
                  break
                end
              end until (j >= @arguments.size) || (@arguments[j] =~ /\//)
            else
              while (j < @arguments.size) && ((@arguments[j] != " ") && (@arguments[j] != ")"))
                current_token_value << @arguments[j]
                j += 1
              end
            end
          else
            begin
              if @arguments[j+1] == "("
                func = true
                be_greedy = true
              end
              current_token_value << @arguments[j]
              if be_greedy
                while !(j+1 >= @arguments.size) && @arguments[j] != ')'
                  j += 1
                  current_token_value << @arguments[j]
                end
                j += 1
                be_greedy = false
              else
                j += 1
              end
            end until (j >= @arguments.size) || (@arguments[j] =~ /\s|\)/)
          end
        rescue Exception => e
          raise "An exception was raised while trying to tokenize '#{current_token_value} - #{e}'"
        end

        @token_index += current_token_value.size - 1

        # bar(
        if current_token_value.match(/.+?\($/)
          return "bad_token", [@token_index - current_token_value.size + 1, @token_index]
        # /foo/=bar
        elsif current_token_value.match(/^\/.+?\/(<|>|=).+/)
          return "bad_token", [@token_index - current_token_value.size + 1, @token_index]
        elsif current_token_value.match(/^.+?\/(<|>|=).+/)
          return "bad_token", [@token_index - current_token_value.size + 1, @token_index]
        else
          if func
            if current_token_value.match(/^.+?\((\s*'[^']+'\s*(,\s*'[^']+')*)?\)(\.[a-zA-Z0-9_]+)?((=|<|>).+)?$/)
              return "fstatement", current_token_value
            else
              return "bad_token", [@token_index - current_token_value.size + 1, @token_index]
            end
          else
            slash_err = false
            current_token_value.split('').each do |c|
              if c == '/'
                slash_err = !slash_err
              end
            end
            return "bad_token", [@token_index - current_token_value.size + 1, @token_index] if slash_err
            return "statement", current_token_value
          end
        end
      end
    end
  end
end
