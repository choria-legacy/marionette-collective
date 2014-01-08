#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Cache do
    before do
      @locks_mutex = Cache.instance_variable_set("@locks_mutex", Mutex.new)
      @cache_locks = Cache.instance_variable_set("@cache_locks", {})
      @cache = Cache.instance_variable_set("@cache", {})
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
        Cache.setup("rspec")
        Cache.delete!("rspec").should == true
      end
    end

    describe "#write" do
      it "should detect unknown caches" do
        expect { Cache.write("rspec", :key, :val) }.to raise_error("No cache called 'rspec'")
      end

      it "should write to the cache" do
        time = Time.now
        Time.expects(:now).returns(time)

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
        Cache.read("rspec", :key).should == :val
      end

      it "should raise on expired reads" do
        Cache.setup("rspec")
        Cache.write("rspec", :key, :val)

        Cache.expects(:ttl).returns(0)

        expect { Cache.read("rspec", :key) }.to raise_error(/has expired/)
      end
    end

    describe "#ttl" do
      it "should return a positive value for an unexpired item" do
        Cache.setup("rspec", 300)
        Cache.write("rspec", :key, :val)
        Cache.ttl("rspec", :key).should >= 0
      end

      it "should return <0 for an expired item" do
        Cache.setup("rspec", 300)
        Cache.write("rspec", :key, :val)

        time = Time.now + 600
        Time.expects(:now).returns(time)

        Cache.ttl("rspec", :key).should <= 0
      end
    end

    describe "#synchronize" do
      it "should use the correct mutex" do
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
