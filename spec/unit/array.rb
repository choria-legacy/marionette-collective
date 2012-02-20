#!/usr/bin/env rspec

require 'spec_helper'

class Array
  describe "#in_groups_of" do
    it "should correctly group array members" do
      [1,2,3,4,5,6,7,8,9,10].in_groups_of(5).should == [[1,2,3,4,5], [6,7,8,9,10]]
    end

    it "should padd missing data with correctly" do
      arr = [1,2,3,4,5,6,7,8,9,10]

      arr.in_groups_of(3).should == [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, nil, nil]]
      arr.in_groups_of(3, 0).should == [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 0, 0]]
      arr.in_groups_of(11).should == [[1,2,3,4,5, 6,7,8,9,10, nil]]
      arr.in_groups_of(11, 0).should == [[1,2,3,4,5, 6,7,8,9,10, 0]]
    end

    it "should indicate when the last abtched was reached" do
      arr = [1,2,3,4,5,6,7,8,9,10]

      ctr = 0

      [1,2,3,4,5,6,7,8,9,10].in_groups_of(3) {|a, last_batch| ctr += 1 unless last_batch}

      ctr.should == 3
    end
  end
end
