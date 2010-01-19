module MCollective
    module Audit
        # This is the base class for the SimpleRPC Audit frameowkr
        # see the documentation in the MCollective::Audit module
        # for details.
        class Base
            def self.inherited(klass)
                PluginManager << {:type => "audit_plugin", :class => klass.to_s}
            end

            def audit_request(request, connection)
                @log.error("audit_request is not implimented in #{this.class}")
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
