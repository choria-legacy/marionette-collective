module MCollective
    module Audit
        # An audit plugin that just logs to a file
        #
        # You can configure which file it logs to with the setting
        #
        #   plugin.logfile_audit.logfile
        class Logfile<Base
            require 'pp'

            def audit_request(request, connection)
                logfile = Config.instance.pluginconf["logfile_audit.logfile"] || "/var/log/mcollective-audit.log"

                Log.instance.debug("Logging to '#{logfile}' - #{logfile.class}")
                File.open(logfile, "w") do |f|
                    f.puts("#{request.uniqid}: #{request.time} caller=#{request.caller} agent=#{request.agent} action=#{request.action} sendernode=#{request.sender}")
                    f.puts("#{request.uniqid}: #{request.data.pretty_print_inspect}")
                end
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
