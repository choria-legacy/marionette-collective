#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module DDL
    describe DataDDL do
      before :each do
        Cache.delete!(:ddl) rescue nil
        @ddl = DDL.new("rspec", :data, false)
        @ddl.metadata(:name => "name", :description => "description", :author => "author", :license => "license", :version => "version", :url => "url", :timeout => "timeout")
      end

      describe "#input" do
        it "should only allow 'query' as input for data plugins" do
          ddl = DDL.new("rspec", :data, false)
          ddl.dataquery(:description => "rspec")
          ddl.instance_variable_set("@current_entity", :query)
          ddl.instance_variable_set("@plugintype", :data)

          expect { ddl.input(:rspec, {}) }.to raise_error("The only valid input name for a data query is 'query'")
        end
      end

      describe "#dataquery_interface" do
        it "should return the correct data" do
          input = {:prompt => "Matcher", :description => "Augeas Matcher", :type => :string, :validation => /.+/, :maxlength => 0}
          output = {:description=>"rspec", :display_as=>"rspec", :default => nil}

          @ddl.instance_variable_set("@plugintype", :data)
          @ddl.dataquery(:description => "rspec") do
            @ddl.output :rspec, output
            @ddl.input :query, input
          end

          @ddl.dataquery_interface.should == {:description => "rspec",
                                              :input => {:query => input.merge(:optional => nil, :default => nil)},
                                              :output => {:rspec => output}}
        end
      end

      describe "#dataquery" do
        it "should ensure a description is set" do
          expect { @ddl.dataquery({}) }.to raise_error("Data queries need a :description")
        end

        it "should ensure only one definition" do
          @ddl.dataquery(:description => "rspec")

          expect { @ddl.dataquery(:description => "rspec") }.to raise_error("Data queries can only have one definition")
        end

        it "should create the default structure" do
          @ddl.dataquery(:description => "rspec")
          @ddl.instance_variable_set("@plugintype", :data)
          @ddl.dataquery_interface.should == {:description => "rspec", :input => {}, :output => {}}
        end

        it "should call the block if given" do
          @ddl.dataquery(:description => "rspec") { @ddl.instance_variable_get("@current_entity").should == :data }
        end
      end
    end
  end
end
