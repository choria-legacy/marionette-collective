#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module DDL
    describe DiscoveryDDL do
      before :each do
        Cache.delete!(:ddl) rescue nil
        @ddl = DDL.new("rspec", :discovery, false)
        @ddl.metadata(:name => "name", :description => "description", :author => "author", :license => "license", :version => "version", :url => "url", :timeout => "timeout")
      end

      describe "#discovery_interface" do
        it "should return correct data" do
          @ddl.instance_variable_set("@plugintype", :discovery)
          @ddl.discovery do
            @ddl.capabilities :identity
          end

          @ddl.discovery_interface.should == {:capabilities => [:identity]}
        end
      end

      describe "#capabilities" do
        it "should support non arrays" do
          @ddl.instance_variable_set("@plugintype", :discovery)
          @ddl.discovery do
            @ddl.capabilities :identity
          end
          @ddl.discovery_interface.should == {:capabilities => [:identity]}
        end

        it "should not accept empty capability lists" do
          @ddl.instance_variable_set("@plugintype", :discovery)
          @ddl.discovery do
            expect { @ddl.capabilities [] }.to raise_error("Discovery plugin capabilities can't be empty")
          end
        end

        it "should only accept known capabilities" do
          @ddl.instance_variable_set("@plugintype", :discovery)
          @ddl.discovery do
            expect { @ddl.capabilities :rspec }.to raise_error(/rspec is not a valid capability/)
          end
        end

        it "should correctly store the capabilities" do
          @ddl.instance_variable_set("@plugintype", :discovery)
          @ddl.discovery do
            @ddl.capabilities [:identity, :classes]
          end
          @ddl.discovery_interface.should == {:capabilities => [:identity, :classes]}
        end
      end
    end
  end
end
