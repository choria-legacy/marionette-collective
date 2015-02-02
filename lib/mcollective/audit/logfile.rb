module MCollective
  module RPC
    # An audit plugin that just logs to a file
    #
    # You can configure which file it logs to with the setting
    #
    #   plugin.rpcaudit.logfile

    class Logfile<Audit
      require 'pp'

      def audit_request(request, connection)
        logfile = Config.instance.pluginconf["rpcaudit.logfile"] || "/var/log/mcollective-audit.log"

        now = Time.now
        # Already told timezone to be in UTC so we don't look it up again
        # This avoids platform specific timezone representation issues
        now_iso8601 = now.utc.strftime("%Y-%m-%d %H:%M:%S UTC")

        File.open(logfile, "a") do |f|
          f.puts("[#{now_iso8601}] reqid=#{request.uniqid}: reqtime=#{request.time} caller=#{request.caller}@#{request.sender} agent=#{request.agent} action=#{request.action} data=#{request.data.pretty_print_inspect}")
        end
      end
    end
  end
end
