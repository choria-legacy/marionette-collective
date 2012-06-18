module MCollective
  class Aggregate
    module Result
      autoload :Base, 'mcollective/aggregate/result/base'
      autoload :NumericResult, 'mcollective/aggregate/result/numeric_result'
      autoload :CollectionResult, 'mcollective/aggregate/result/collection_result'
    end
  end
end
