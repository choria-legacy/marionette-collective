#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe RPC do
    describe "#const_missing" do
      it "should deprecate only the DDL class" do
        Log.expects(:warn).with("MCollective::RPC::DDL is deprecatd, please use MCollective::DDL instead")
        MCollective::RPC::DDL.should == MCollective::DDL

        expect { MCollective::RPC::Foo }.to raise_error(NameError)
      end
    end
  end
end
