metadata    :name        => "rpcutil",
            :description => "General helpful actions that expose stats and internals to SimpleRPC clients",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "Apache License, Version 2.0",
            :version     => "1.0",
            :url         => "https://docs.puppetlabs.com/mcollective/",
            :timeout     => 10

action "collective_info", :description => "Info about the main and sub collectives" do
    display :always

    output :main_collective,
           :description => "The main Collective",
           :display_as => "Main Collective"

    output :collectives,
           :description => "All Collectives",
           :display_as => "All Collectives"

    summarize do
        aggregate summary(:collectives)
    end
end

action "inventory", :description => "System Inventory" do
    display :always

    output :agents,
           :description => "List of agent names",
           :display_as => "Agents"

    output :facts,
           :description => "List of facts and values",
           :display_as => "Facts"

    output :classes,
           :description => "List of classes on the system",
           :display_as => "Classes"

    output :version,
           :description => "MCollective Version",
           :display_as => "Version"

    output :main_collective,
           :description => "The main Collective",
           :display_as => "Main Collective"

    output :collectives,
           :description => "All Collectives",
           :display_as => "All Collectives"

    output :data_plugins,
           :description => "List of data plugin names",
           :display_as => "Data Plugins"
end

action "get_fact", :description => "Retrieve a single fact from the fact store" do
     display :always

     input :fact,
           :prompt      => "The name of the fact",
           :description => "The fact to retrieve",
           :type        => :string,
           :validation  => '^[\w\-\.]+$',
           :optional    => false,
           :maxlength   => 40

     output :fact,
            :description => "The name of the fact being returned",
            :display_as => "Fact"

     output :value,
            :description => "The value of the fact",
            :display_as => "Value"

    summarize do
        aggregate summary(:value)
    end
end

action "get_facts", :description => "Retrieve multiple facts from the fact store" do
     display :always

     input :facts,
           :prompt      => "Comma-separated list of facts",
           :description => "Facts to retrieve",
           :type        => :string,
           :validation  => '^\s*[\w\.\-]+(\s*,\s*[\w\.\-]+)*$',
           :optional    => false,
           :maxlength   => 200

     output :values,
            :description => "List of values of the facts",
            :display_as => "Values"
end

action "daemon_stats", :description => "Get statistics from the running daemon" do
    display :always

    output :threads,
           :description => "List of threads active in the daemon",
           :display_as => "Threads"

    output :agents,
           :description => "List of agents loaded",
           :display_as => "Agents"

    output :pid,
           :description => "Process ID of the daemon",
           :display_as => "PID"

    output :times,
           :description => "Processor time consumed by the daemon",
           :display_as => "Times"

    output :validated,
           :description => "Messages that passed security validation",
           :display_as => "Security Validated"

    output :unvalidated,
           :description => "Messages that failed security validation",
           :display_as => "Failed Security"

    output :passed,
           :description => "Passed filter checks",
           :display_as => "Passed Filter"

    output :filtered,
           :description => "Didn't pass filter checks",
           :display_as => "Failed Filter"

    output :starttime,
           :description => "Time the server started",
           :display_as => "Start Time"

    output :total,
           :description => "Total messages received",
           :display_as => "Total Messages"

    output :replies,
           :description => "Replies sent back to clients",
           :display_as => "Replies"

    output :configfile,
           :description => "Config file used to start the daemon",
           :display_as => "Config File"

    output :version,
           :description => "MCollective Version",
           :display_as => "Version"

    output :ttlexpired,
           :description => "Messages that did pass TTL checks",
           :display_as => "TTL Expired"

    summarize do
        aggregate summary(:version)
        aggregate summary(:agents)
    end
end

action "agent_inventory", :description => "Inventory of all agents on the server" do
    display :always

    output :agents,
           :description => "List of agents on the server",
           :display_as => "Agents"
end

action "get_config_item", :description => "Get the active value of a specific config property" do
    display :always

    input :item,
          :prompt      => "Configuration Item",
          :description => "The item to retrieve from the server",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => false,
          :maxlength    => 50

    output :item,
           :description => "The config property being retrieved",
           :display_as => "Property"

    output :value,
           :description => "The value that is in use",
           :display_as => "Value"

    summarize do
        aggregate summary(:value)
    end
end

action "get_data", :description => "Get data from a data plugin" do
    display :always

    input :source,
          :prompt      => "Data Source",
          :description => "The data plugin to retrieve information from",
          :type        => :string,
          :validation  => '^\w+$',
          :optional    => false,
          :maxlength   => 50

    input :query,
          :prompt      => "Query",
          :description => "The query argument to supply to the data plugin",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => true,
          :maxlength   => 200
end

action "ping", :description => "Responds to requests for PING with PONG" do
    display :always

    output :pong,
           :description => "The local timestamp",
           :display_as => "Timestamp"
end
