module MCollective
  module Matcher
    class Parser
      attr_reader :scanner, :execution_stack

      def initialize(args)
        @scanner = Scanner.new(args)
        @execution_stack = []
        parse
      end

      # Parse the input string, one token at a time a contruct the call stack
      def parse
        p_token,p_token_value = nil
        c_token,c_token_value = @scanner.get_token
        parenth = 0

        while (c_token != nil)
          @scanner.token_index += 1
          n_token, n_token_value = @scanner.get_token

          unless n_token == " "
            case c_token
            when "and"
              unless (n_token =~ /not|statement|\(/) || (scanner.token_index == scanner.arguments.size)
                raise "Error at column #{scanner.token_index}. \nExpected 'not', 'statement' or '('. Found '#{n_token_value}'"
              end

              if p_token == nil
                raise "Error at column #{scanner.token_index}. \n Expression cannot start with 'and'"
              elsif (p_token == "and" || p_token == "or")
                raise "Error at column #{scanner.token_index}. \n #{p_token} cannot be followed by 'and'"
              end

            when "or"
              unless (n_token =~ /not|statement|\(/) || (scanner.token_index == scanner.arguments.size)
                raise "Error at column #{scanner.token_index}. \nExpected 'not', 'statement', '('. Found '#{n_token_value}'"
              end

              if p_token == nil
                raise "Error at column #{scanner.token_index}. \n Expression cannot start with 'or'"
              elsif (p_token == "and" || p_token == "or")
                raise "Error at column #{scanner.token_index}. \n #{p_token} cannot be followed by 'or'"
              end

            when "not"
              unless n_token =~ /statement|\(|not/
                raise "Error at column #{scanner.token_index}. \nExpected 'statement' or '('. Found '#{n_token_value}'"
              end

            when "statement"
              unless n_token =~ /and|or|\)/
                unless scanner.token_index == scanner.arguments.size
                  raise "Error at column #{scanner.token_index}. \nExpected 'and', 'or', ')'. Found '#{n_token_value}'"
                end
              end

            when ")"
              unless (n_token =~ /|and|or|not|\(/)
                unless(scanner.token_index == scanner.arguments.size)
                  raise "Error at column #{scanner.token_index}. \nExpected 'and', 'or', 'not' or '('. Found '#{n_token_value}'"
                end
              end
              parenth += 1

            when "("
              unless n_token =~ /statement|not|\(/
                raise "Error at column #{scanner.token_index}. \nExpected 'statement', '(',  not. Found '#{n_token_value}'"
              end
              parenth -= 1

            else
              raise "Unexpected token found at column #{scanner.token_index}. '#{c_token_value}'"
            end

            unless n_token == " "
              @execution_stack << {c_token => c_token_value}
            end

            p_token, p_token_value = c_token, c_token_value
            c_token, c_token_value = n_token, n_token_value
          end
        end

        if parenth < 0
          raise "Error. Missing parentheses ')'."
        elsif parenth > 0
          raise "Error. Missing parentheses '('."
        end
      end
    end
  end
end
