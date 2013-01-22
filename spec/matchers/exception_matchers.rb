module MCollective
  module Matchers
    def raise_code(*args)
      CodedExceptionMatcher.new(args)
    end

    class CodedExceptionMatcher
      def initialize(args)
        @args = args

        raise "Need at least an exception to match" if args.size == 0

        @expected_code = @args.shift
        @expected_data = @args.shift

        @failure_type = nil
        @failure_expected = nil
        @failure_got = nil
      end

      def matches?(actual)
        begin
          actual.call
        rescue => e
          unless e.is_a?(MCollective::CodedError)
            @failure_type = :type
            @failure_expected = "MCollective::CodedError"
            @failure_got = e.class
            return false
          end

          unless [e.code, e.default].include?(@expected_code)
            @failure_type = :code
            @failure_expected = @expected_code
            @failure_got = e.code
            return false
          end

          if @expected_data
            unless e.args == @expected_data
              @failure_type = :arguments
              @failure_expected = @expected_data.inspect
              @failure_got = e.args.inspect
              return false
            end
          end
        end

        true
      end

      def failure_message
        case @failure_type
          when :type
            "Expected an exception of type %s but got %s" % [@failure_expected, @failure_got]
          when :code
            "Expected a message code %s but got %s" % [@failure_expected, @failure_got]
          when :arguments
            "Expected arguments %s but got %s" % [@failure_expected, @failure_got]
        end
      end

      def negative_failure_message
        case @failure_type
          when :type
            "Expected an exception of type %s but got %s" % [@failure_got, @failure_expected]
          when :code
            "Expected a message code %s but got %s" % [@failure_got, @failure_expected]
          when :arguments
            "Expected arguments %s but got %s" % [@failure_got, @failure_expected]
        end
      end
    end
  end
end
