metadata  :name        => "summary",
          :description => "Displays the summary of a set of results",
          :author      => "Pieter Loubser <pieter.loubser@puppetlabs.com>",
          :license     => "ASL 2.0",
          :version     => "1.0",
          :url         => "https://docs.puppetlabs.com/mcollective/plugin_directory/",
          :timeout     => 5

usage <<-USAGE

  This aggregate plugin will display the summary of a set of results.

  DDL Example:

    summarize do
      aggregate summary(:value)
    end

  Sample Output:

    host1.example.com
      Property: collectives
          Value: ["mcollective", "uk_collective"]

    Summary of Value:

        mcollective = 25
      uk_collective = 15
      fr_collective = 9
      us_collective = 1

USAGE

