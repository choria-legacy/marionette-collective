#!/usr/bin/env rspec

require 'spec_helper'

require File.dirname(__FILE__) + "/../../../../../plugins/mcollective/data/fstat_data.rb"

module MCollective
  module Data
    describe Fstat_data do
      describe "#query_data" do
        before do
          @ddl = mock
          @ddl.stubs(:meta).returns({:timeout => 1})
          DDL.stubs(:new).returns(@ddl)
          @plugin = Fstat_data.new

          @time = Time.now

          @stat = mock
          @stat.stubs(:size).returns(123)
          @stat.stubs(:uid).returns(0)
          @stat.stubs(:gid).returns(0)
          @stat.stubs(:mtime).returns(@time)
          @stat.stubs(:ctime).returns(@time)
          @stat.stubs(:atime).returns(@time)
          @stat.stubs(:mode).returns(33188)
          @stat.stubs(:directory?).returns(false)
          @stat.stubs(:file?).returns(false)
          @stat.stubs(:symlink?).returns(false)
          @stat.stubs(:socket?).returns(false)
          @stat.stubs(:chardev?).returns(false)
          @stat.stubs(:blockdev?).returns(false)
        end

        it "should detect missing files" do
          File.expects(:exists?).with("/nonexisting").returns(false)
          @plugin.query_data("/nonexisting")
          @plugin.result.output.should == "not present"
        end

        it "should provide correct file stats" do
          File.expects(:exists?).with("rspec").returns(true)
          File.expects(:symlink?).with("rspec").returns(false)
          File.expects(:stat).with("rspec").returns(@stat)
          File.expects(:read).with("rspec").returns("rspec")

          @stat.stubs(:file?).returns(true)

          @plugin.query_data("rspec")
          @plugin.result.output.should == "present"
          @plugin.result.size.should == 123
          @plugin.result.uid.should == 0
          @plugin.result.gid.should == 0
          @plugin.result.mtime.should == @time.strftime("%F %T")
          @plugin.result.mtime_seconds.should == @time.to_i
          @plugin.result.mtime_age.should <= 5
          @plugin.result.ctime.should == @time.strftime("%F %T")
          @plugin.result.ctime_seconds.should == @time.to_i
          @plugin.result.ctime_age.should <= 5
          @plugin.result.atime.should == @time.strftime("%F %T")
          @plugin.result.atime_seconds.should == @time.to_i
          @plugin.result.atime_age.should <= 5
          @plugin.result.mode.should == "100644"
          @plugin.result.md5.should == "2bc84dc69b73db9383b9c6711d2011b7"
          @plugin.result.type.should == "file"
        end

        it "should provide correct link stats" do
          File.expects(:exists?).with("rspec").returns(true)
          File.expects(:symlink?).with("rspec").returns(true)
          File.expects(:lstat).with("rspec").returns(@stat)

          @stat.stubs(:symlink?).returns(true)

          @plugin.query_data("rspec")
          @plugin.result.output.should == "present"
          @plugin.result.md5.should == 0
          @plugin.result.type.should == "symlink"
        end

        it "should provide correct directory stats" do
          File.expects(:exists?).with("rspec").returns(true)
          File.expects(:symlink?).with("rspec").returns(false)
          File.expects(:stat).with("rspec").returns(@stat)

          @stat.stubs(:directory?).returns(true)

          @plugin.query_data("rspec")
          @plugin.result.output.should == "present"
          @plugin.result.md5.should == 0
          @plugin.result.type.should == "directory"
        end

        it "should provide correct socket stats" do
          File.expects(:exists?).with("rspec").returns(true)
          File.expects(:symlink?).with("rspec").returns(false)
          File.expects(:stat).with("rspec").returns(@stat)

          @stat.stubs(:socket?).returns(true)

          @plugin.query_data("rspec")
          @plugin.result.output.should == "present"
          @plugin.result.md5.should == 0
          @plugin.result.type.should == "socket"
        end

        it "should provide correct chardev stats" do
          File.expects(:exists?).with("rspec").returns(true)
          File.expects(:symlink?).with("rspec").returns(false)
          File.expects(:stat).with("rspec").returns(@stat)

          @stat.stubs(:chardev?).returns(true)

          @plugin.query_data("rspec")
          @plugin.result.output.should == "present"
          @plugin.result.md5.should == 0
          @plugin.result.type.should == "chardev"
        end

        it "should provide correct blockdev stats" do
          File.expects(:exists?).with("rspec").returns(true)
          File.expects(:symlink?).with("rspec").returns(false)
          File.expects(:stat).with("rspec").returns(@stat)

          @stat.stubs(:blockdev?).returns(true)

          @plugin.query_data("rspec")
          @plugin.result.output.should == "present"
          @plugin.result.md5.should == 0
          @plugin.result.type.should == "blockdev"
        end
      end
    end
  end
end
