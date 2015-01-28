module MCollective
  # This is a class that gives access to the configured fact provider
  # such as MCollectives::Facts::Facter that uses Reductive Labs facter
  #
  # The actual provider is pluggable and configurable using the 'factsource'
  # configuration option.
  #
  # To develop a new factsource simply create a class under MCollective::Facts::
  # and provide the following classes:
  #
  #   self.get_fact(fact)
  #   self.has_fact?(fact)
  #
  # You can also just inherit from MCollective::Facts::Base and provide just the
  #
  #   self.get_facts
  #
  # method that should return a hash of facts.
  module Facts
    require "mcollective/facts/base"

    @@config = nil

    # True if we know of a specific fact else false
    def self.has_fact?(fact, value)
      PluginManager["facts_plugin"].get_fact(fact) == value ? true : false
    end

    # Get the value of a fact
    def self.get_fact(fact)
      PluginManager["facts_plugin"].get_fact(fact)
    end

    # Get the value of a fact
    def self.[](fact)
      PluginManager["facts_plugin"].get_fact(fact)
    end
  end
end
