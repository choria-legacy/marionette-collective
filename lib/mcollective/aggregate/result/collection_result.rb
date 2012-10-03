module MCollective
  class Aggregate
    module Result
      class CollectionResult<Base
        def to_s
          return "" if @result[:value].keys.include?(nil)

          result = StringIO.new

          @result[:value].sort{|x,y| x[1] <=> y[1]}.reverse.each do |value|
            result.puts @aggregate_format % [value[0], value[1]]
          end

          result.string.chomp
        end
      end
    end
  end
end
