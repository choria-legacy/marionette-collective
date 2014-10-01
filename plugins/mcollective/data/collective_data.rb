module MCollective
  module Data
    class Collective_data<Base
      query do |collective|
        result[:member] = Config.instance.collectives.include?(collective)
      end
    end
  end
end
