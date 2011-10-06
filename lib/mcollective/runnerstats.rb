module MCollective
  # Class to store stats about the mcollectived, it should live in the PluginManager
  # so that agents etc can get hold of it and return the stats to callers
  class RunnerStats
    def initialize
      @starttime = Time.now.to_i
      @validated = 0
      @unvalidated = 0
      @filtered = 0
      @passed = 0
      @total = 0
      @replies = 0
      @ttlexpired = 0

      @mutex = Mutex.new
    end

    # Records a message that failed TTL checks
    def ttlexpired
      Log.debug("Incrementing ttl expired stat")
      @ttlexpired += 1
    end

    # Records a message that passed the filters
    def passed
      Log.debug("Incrementing passed stat")
      @passed += 1
    end

    # Records a message that didnt pass the filters
    def filtered
      Log.debug("Incrementing filtered stat")
      @filtered += 1
    end

    # Records a message that validated ok
    def validated
      Log.debug("Incrementing validated stat")
      @validated += 1
    end

    def unvalidated
      Log.debug("Incrementing unvalidated stat")
      @unvalidated += 1
    end

    # Records receipt of a message
    def received
      Log.debug("Incrementing total stat")
      @total += 1
    end

    # Records sending a message
    def sent
      @mutex.synchronize do
        Log.debug("Incrementing replies stat")
        @replies += 1
      end
    end

    # Returns a hash with all stats
    def to_hash
      stats = {:validated => @validated,
        :unvalidated => @unvalidated,
        :passed => @passed,
        :filtered => @filtered,
        :starttime => @starttime,
        :total => @total,
        :ttlexpired => @ttlexpired,
        :replies => @replies}

      reply = {:stats => stats,
        :threads => [],
        :pid => Process.pid,
        :times => {} }

      ::Process.times.each_pair{|k,v|
        k = k.to_sym
        reply[:times][k] = v
      }

      Thread.list.each do |t|
        reply[:threads] << "#{t.inspect}"
      end

      reply[:agents] = Agents.agentlist
      reply
    end
  end
end
