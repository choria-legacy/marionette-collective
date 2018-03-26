module MCollective
  module Matcher
    class Scanner
      attr_accessor :arguments, :token_index

      def initialize(arguments)
        @token_index = 0
        @arguments = arguments.split("")
        @seperation_counter = 0
        @white_spaces = 0
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
        escaped = false

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
              while (j < @arguments.size) && ((@arguments[j] != " ") && (@arguments[j] != ")"))
                current_token_value << @arguments[j]
                j += 1
              end
            end
          else
            begin
              # Identify and tokenize regular expressions by ignoring everything between /'s
              if @arguments[j] == '/'
                current_token_value << '/'
                j += 1
                while(j < @arguments.size && @arguments[j] != '/')
                  if  @arguments[j] == '\\'
                    # eat the escape char
                    current_token_value << @arguments[j]
                    j += 1
                    escaped = true
                  end

                  current_token_value << @arguments[j]
                  j += 1
                end
                current_token_value << @arguments[j] if @arguments[j]
                break
              end

              if @arguments[j] == "("
                func = true

                current_token_value << @arguments[j]
                j += 1

                while j < @arguments.size
                  current_token_value << @arguments[j]
                  if @arguments[j] == ')'
                    j += 1
                    break
                  end
                  j += 1
                end
              elsif @arguments[j] == '"' || @arguments[j] == "'"
                escaped = true
                escaped_with = @arguments[j]

                j += 1 # step over first " or '
                @white_spaces += 1
                # identified "..." or '...'
                while j < @arguments.size
                  if  @arguments[j] == '\\'
                    # eat the escape char but don't add it to the token, or we
                    # end up with \\\"
                    j += 1
                    @white_spaces += 1
                    unless j < @arguments.size
                      break
                    end
                  elsif @arguments[j] == escaped_with
                    j += 1
                    @white_spaces += 1
                    break
                  end
                  current_token_value << @arguments[j]
                  j += 1
                end
              else
                current_token_value << @arguments[j]
                j += 1
              end

              if(@arguments[j] == ' ')
                break if(is_klass?(j) && !(@arguments[j-1] =~ /=|<|>/))
              end

              if( (@arguments[j] == ' ') && (@seperation_counter < 2) && !(current_token_value.match(/^.+(=|<|>).+$/)) )
                if((index = lookahead(j)))
                  j = index
                end
              end
            end until (j >= @arguments.size) || (@arguments[j] =~ /\s|\)/)
            @seperation_counter = 0
          end
        rescue Exception => e
          raise "An exception was raised while trying to tokenize '#{current_token_value} - #{e}'"
        end

        @token_index += current_token_value.size + @white_spaces - 1
        @white_spaces = 0

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
            if current_token_value.match(/^.+?\((\s*(')[^']*(')\s*(,\s*(')[^']*('))*)?\)(\.[a-zA-Z0-9_]+)?((!=|<=|>=|=|>|<).+)?$/) ||
               current_token_value.match(/^.+?\((\s*(")[^"]*(")\s*(,\s*(")[^"]*("))*)?\)(\.[a-zA-Z0-9_]+)?((!=|<=|>=|=|>|<).+)?$/)
              return "fstatement", current_token_value
            else
              return "bad_token", [@token_index - current_token_value.size + 1, @token_index]
            end
          else
            if escaped
              return "statement", current_token_value
            end
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

      # Deal with special puppet class statement
      def is_klass?(j)
        while(j < @arguments.size && @arguments[j] == ' ')
          j += 1
        end

        if @arguments[j] =~ /=|<|>/
          return false
        else
          return true
        end
      end

      # Eat spaces while looking for the next comparison symbol
      def lookahead(index)
        index += 1
        while(index <= @arguments.size)
          @white_spaces += 1
          unless(@arguments[index] =~ /\s/)
            @seperation_counter +=1
            return index
          end
          index += 1
        end
        return nil
      end
    end
  end
end
