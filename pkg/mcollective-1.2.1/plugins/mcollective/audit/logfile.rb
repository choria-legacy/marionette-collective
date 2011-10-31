module MCollective
    module RPC
        # An audit plugin that just logs to a file
        #
        # You can configure which file it logs to with the setting
        #
        #   plugin.rpcaudit.logfile
        #
        class Logfile<Audit
            require 'pp'

            def audit_request(request, connection)
                logfile = Config.instance.pluginconf["rpcaudit.logfile"] || "/var/log/mcollective-audit.log"

                now = Time.now
                now_tz = tz = now.utc? ? "Z" : now.strftime("%z")
                now_iso8601 = "%s.%06d%s" % [now.strftime("%Y-%m-%dT%H:%M:%S"), now.tv_usec, now_tz]

                File.open(logfile, "a") do |f|
                    f.puts("#{now_iso8601}: reqid=#{request.uniqid}: reqtime=#{request.time} caller=#{request.caller}@#{request.sender} agent=#{request.agent} action=#{request.action} data=#{request.data.pretty_print_inspect}")
                end
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
