module MCollective
  class Aggregate
    module Result
      class NumericResult<Base
        def to_s
          return "" if @result[:value].nil?

          return @aggregate_format % @result[:value]
        end
      end
    end
  end
end
