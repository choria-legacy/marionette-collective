#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Cache do
    before do
      @locks_mutex = Cache.instance_variable_set("@locks_mutex", Mutex.new)
      @cache_locks = Cache.instance_variable_set("@cache_locks", {})
      @cache = Cache.instance_variable_set("@cache", {})
    end

    describe "#check_cache!" do
      it "should correctly check for valid caches" do
        Cache.expects(:has_cache?).with("rspec").returns(true)
        Cache.expects(:has_cache?).with("fail").returns(false)

        Cache.check_cache!("rspec")
        expect { Cache.check_cache!("fail") }.to raise_code("Could not find a cache called '%{cache_name}'", :cache_name => "fail")
      end
    end

    describe "#setup" do
      it "should use a mutex to manage access to the cache" do
        @locks_mutex.expects(:synchronize).yields
        Cache.setup("x").should == true
        @cache.should == {"x" => {:max_age => 300.0}}
      end

      it "should correctly setup a new cache" do
        @locks_mutex.expects(:synchronize).twice.yields
        Cache.setup("rspec1", 300)
        @cache["rspec1"].should == {:max_age => 300.0}

        Cache.setup("rspec2")
        @cache["rspec2"].should == {:max_age => 300.0}
      end
    end

    describe "#has_cache?" do
      it "should correctly report presense of a cache" do
        Cache.setup("rspec")
        Cache.has_cache?("rspec").should == true
        Cache.has_cache?("fail").should == false
      end
    end

    describe "#delete!" do
      it "should delete the cache and return true" do
        Cache.expects(:check_cache!).with("rspec")

        Cache.setup("rspec")
        Cache.delete!("rspec").should == true
      end
    end

    describe "#write" do
      it "should write to the cache" do
        time = Time.now
        Time.expects(:now).returns(time)
        Cache.expects(:check_cache!).with("rspec")

        Cache.setup("rspec")
        Cache.write("rspec", :key, :val).should == :val

        @cache["rspec"][:key][:value].should == :val
        @cache["rspec"][:key][:cache_create_time].should == time
      end
    end

    describe "#read" do
      it "should read a written entry correctly" do
        Cache.setup("rspec")
        Cache.write("rspec", :key, :val)

        Cache.expects(:check_cache!).with("rspec")
        Cache.expects(:ttl).with("rspec", :key).returns(1)

        Cache.read("rspec", :key).should == :val
      end

      it "should raise on expired reads" do
        Cache.setup("rspec")
        Cache.write("rspec", :key, :val)

        Cache.expects(:ttl).returns(0)

        Cache.expects(:check_cache!).with("rspec")

        expect { Cache.read("rspec", :key) }.to raise_code("Cache expired on '%{cache_name}' key '%{item}'", :cache_name => "rspec", :item => :key)
      end
    end

    describe "#invalidate!" do
      it "should return false for unknown keys" do
        Cache.expects(:check_cache!).with("rspec")

        @locks_mutex.expects(:synchronize).yields

        Cache.setup("rspec")
        Cache.invalidate!("rspec", "no_such_key").should == false
      end

      it "should delete the key" do
        Cache.setup("rspec")
        Cache.write("rspec", "valid_key", "rspec")

        Cache.expects(:check_cache!).with("rspec")
        @cache["rspec"].expects(:delete).with("valid_key")

        Cache.invalidate!("rspec", "valid_key")
      end
    end

    describe "#ttl" do
      it "should detect invalid key names" do
        Cache.expects(:check_cache!).with("rspec")
        Cache.setup("rspec", 300)
        expect { Cache.ttl("rspec", :key) }.to raise_code("No item called '%{item}' for cache '%{cache_name}'", :cache_name => "rspec", :item => :key)
      end

      it "should return >0 for valid" do
        Cache.setup("rspec", 300)
        Cache.write("rspec", :key, :val)

        Cache.expects(:check_cache!).with("rspec")
        Cache.ttl("rspec", :key).should >= 0
      end

      it "should return <0 for expired messages" do
        Cache.setup("rspec", 300)
        Cache.write("rspec", :key, :val)

        time = Time.now + 600
        Time.expects(:now).returns(time)

        Cache.expects(:check_cache!).with("rspec")
        Cache.ttl("rspec", :key).should <= 0
      end
    end

    describe "#synchronize" do
      it "should use the correct mutex" do
        Cache.expects(:check_cache!).with("rspec")
        Cache.setup("rspec")

        rspec_lock = @cache_locks["rspec"]
        rspec_lock.expects(:synchronize).yields

        @cache_locks.expects("[]").with("rspec").returns(rspec_lock)

        ran = 0
        Cache.synchronize("rspec") do
          ran = 1
        end

        ran.should == 1
      end
    end
  end
end
