module MCollective
    module RPC
        # An audit plugin that just logs to a file
        #
        # You can configure which file it logs to with the setting
        #
        #   plugin.rpcaudit.logfile
        #
        class Logfile<Audit
            def audit_request(request, connection)
                require 'pp'

                logfile = Config.instance.pluginconf["rpcaudit.logfile"] || "/var/log/mcollective-audit.log"

                File.open(logfile, "a") do |f|
                    f.puts("#{request.uniqid}: #{request.time} caller=#{request.caller}@#{request.sender} agent=#{request.agent} action=#{request.action}")
                    f.puts("#{request.uniqid}: #{request.data.pretty_print_inspect}")
                end
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
