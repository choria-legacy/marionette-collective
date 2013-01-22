module MCollective
  # A class to manage a number of named caches.  Each cache can have a unique
  # timeout for keys in it and each cache has an independent Mutex protecting
  # access to it.
  #
  # This cache is setup early in the process of loading the mcollective
  # libraries, before any threads are created etc making it suitable as a
  # cross thread cache or just a store for Mutexes you need to use across
  # threads like in an Agent or something.
  #
  #    # sets up a new cache, noop if it already exist
  #    Cache.setup(:ddl, 600)
  #    => true
  #
  #    # writes an item to the :ddl cache, this item will
  #    # be valid on the cache for 600 seconds
  #    Cache.write(:ddl, :something, "value")
  #    => "value"
  #
  #    # reads from the cache, read failures due to non existing
  #    # data or expired data will raise an exception
  #    Cache.read(:ddl, :something)
  #    => "value"
  #
  #    # time left till expiry, raises if nothing is found
  #    Cache.ttl(:ddl, :something)
  #    => 500
  #
  #    # forcibly evict something from the cache
  #    Cache.invalidate!(:ddl, :something)
  #    => "value"
  #
  #    # deletes an entire named cache and its mutexes
  #    Cache.delete!(:ddl)
  #    => true
  #
  #    # you can also just use this cache as a global mutex store
  #    Cache.setup(:mylock)
  #
  #    Cache.synchronize(:mylock) do
  #      do_something()
  #    end
  #
  module Cache
    extend Translatable

    # protects access to @cache_locks and top level @cache
    @locks_mutex = Mutex.new

    # stores a mutex per named cache
    @cache_locks = {}

    # the named caches protected by items in @cache_locks
    @cache = {}

    def self.setup(cache_name, ttl=300)
      @locks_mutex.synchronize do
        break if @cache_locks.include?(cache_name)

        @cache_locks[cache_name] = Mutex.new

        @cache_locks[cache_name].synchronize do
          @cache[cache_name] = {:max_age => Float(ttl)}
        end
      end

      true
    end

    def self.check_cache!(cache_name)
      raise_code(:PLMC13, "Could not find a cache called '%{cache_name}'", :debug, :cache_name => cache_name) unless has_cache?(cache_name)
    end

    def self.has_cache?(cache_name)
      @locks_mutex.synchronize do
        @cache.include?(cache_name)
      end
    end

    def self.delete!(cache_name)
      check_cache!(cache_name)

      @locks_mutex.synchronize do
        @cache_locks.delete(cache_name)
        @cache.delete(cache_name)
      end

      true
    end

    def self.write(cache_name, key, value)
      check_cache!(cache_name)

      @cache_locks[cache_name].synchronize do
        @cache[cache_name][key] ||= {}
        @cache[cache_name][key][:cache_create_time] = Time.now
        @cache[cache_name][key][:value] = value
      end

      value
    end

    def self.read(cache_name, key)
      check_cache!(cache_name)

      unless ttl(cache_name, key) > 0
        raise_code(:PLMC11, "Cache expired on '%{cache_name}' key '%{item}'", :debug, :cache_name => cache_name, :item => key)
      end

      log_code(:PLMC12, "Cache hit on '%{cache_name}' key '%{item}'", :debug, :cache_name => cache_name, :item => key)

      @cache_locks[cache_name].synchronize do
        @cache[cache_name][key][:value]
      end
    end

    def self.ttl(cache_name, key)
      check_cache!(cache_name)

      @cache_locks[cache_name].synchronize do
        unless @cache[cache_name].include?(key)
          raise_code(:PLMC15, "No item called '%{item}' for cache '%{cache_name}'", :debug, :cache_name => cache_name, :item => key)
        end

        @cache[cache_name][:max_age] - (Time.now - @cache[cache_name][key][:cache_create_time])
      end
    end

    def self.synchronize(cache_name)
      check_cache!(cache_name)

      raise_code(:PLMC14, "No block supplied to synchronize on cache '%{cache_name}'", :debug, :cache_name => cache_name) unless block_given?

      @cache_locks[cache_name].synchronize do
        yield
      end
    end

    def self.invalidate!(cache_name, key)
      check_cache!(cache_name)

      @cache_locks[cache_name].synchronize do
        return false unless @cache[cache_name].include?(key)

        @cache[cache_name].delete(key)
      end
    end
  end
end
