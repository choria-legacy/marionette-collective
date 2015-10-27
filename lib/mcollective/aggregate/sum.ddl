metadata  :name        => "Sum",
          :description => "Determine the total added value of a set of values",
          :author      => "Pieter Loubser <pieter.loubser@puppetlabs.com>",
          :license     => "ASL 2.0",
          :version     => "1.0",
          :url         => "https://docs.puppetlabs.com/mcollective/plugin_directory/",
          :timeout     => 5

usage <<-USAGE

  This aggregate plugin will determine the total added value of a set of values.

  DDL Example:

    summarize do
      aggregate sum(:value)
    end

  Sample Output:

    host1.example.com
      Value: 10

    host2.example.com
      Value: 20


   Summary of Value:

      Sum of Value: 30

USAGE

