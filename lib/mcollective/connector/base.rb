module MCollective
    module Connector
        class Base
            def self.inherited(klass)
                MCollective::PluginManager << {:type => "connector_plugin", :class => klass.to_s}
            end
	end
    end
end
