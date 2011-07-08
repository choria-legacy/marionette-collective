module MCollective
    module Matcher
        class Scanner
            attr_accessor :arguments, :token_index

            def initialize(arguments)
                @token_index = 0
                @arguments = arguments
            end

            # Scans the input string and identifies single language tokens
            def get_token
                if @token_index >= @arguments.size
                    return nil
                end

                begin
                    case @arguments.split("")[@token_index]
                        when "("
                            return "(", "("

                        when ")"
                            return ")", ")"

                        when "n"
                            if (@arguments.split("")[@token_index + 1] == "o") && (@arguments.split("")[@token_index + 2] == "t") && ((@arguments.split("")[@token_index + 3] == " ") || (@arguments.split("")[@token_index + 3] == "("))
                                @token_index += 2
                                return "not", "not"
                            else
                                gen_statement
                            end

                        when "!"
                            return "not", "not"

                        when "a"
                            if (@arguments.split("")[@token_index + 1] == "n") && (@arguments.split("")[@token_index + 2] == "d") && ((@arguments.split("")[@token_index + 3] == " ") || (@arguments.split("")[@token_index + 3] == "("))
                                @token_index += 2
                                return "and", "and"
                            else
                                gen_statement
                            end

                        when "o"
                            if (@arguments.split("")[@token_index + 1] == "r") && ((@arguments.split("")[@token_index + 2] == " ") || (@arguments.split("")[@token_index + 2] == "("))
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
            rescue NoMethodError => e
                pp e
                raise "Cannot end statement with 'and', 'or', 'not'"
            end

            private
            # Helper generates a statement token
            def gen_statement
                current_token_value = ""
                j = @token_index

                begin
                    if (@arguments.split("")[j] == "/")
                        begin
                            current_token_value << @arguments.split("")[j]
                            j += 1
                            if @arguments.split("")[j] == "/"
                                current_token_value << "/"
                                break
                            end
                        end until (j >= @arguments.size) || (@arguments.split("")[j] =~ /\//)
                    elsif (@arguments.split("")[j] =~ /=|<|>/)
                        while !(@arguments.split("")[j] =~ /=|<|>/)
                            current_token_value << @arguments.split("")[j]
                            j += 1
                        end

                        current_token_value << @arguments.split("")[j]
                        j += 1

                        if @arguments.split("")[j] == "/"
                            begin
                                current_token_value << @arguments.split("")[j]
                                j += 1
                                if @arguments.split("")[j] == "/"
                                    current_token_value << "/"
                                    break
                                end
                            end until (j >= @arguments.size) || (@arguments.split("")[j] =~ /\//)
                        else
                            while (j < @arguments.size) && ((@arguments.split("")[j] != " ") && (@arguments.split("")[j] != ")"))
                                current_token_value << @arguments.split("")[j]
                                j += 1
                            end
                        end
                    else
                        begin
                            current_token_value << @arguments.split("")[j]
                            j += 1
                        end until (j >= @arguments.size) || (@arguments.split("")[j] =~ /\s|\)/)
                    end
                rescue Exception => e
                    raise "Invalid token found - '#{current_token_value}'"
                end

                if current_token_value =~ /^(and|or|not|!)$/
                    raise "Class name cannot be 'and', 'or', 'not'. Found '#{current_token_value}'"
                end

                @token_index += current_token_value.size - 1
                return "statement", current_token_value
            end
        end
    end
end
