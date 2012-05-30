module MCollective
  class Discovery
    class Mc
      def self.discover(filter, timeout, limit, client)
        begin
          hosts = []
          Timeout.timeout(timeout) do
            reqid = client.sendreq("ping", "discovery", filter)
            Log.debug("Waiting #{timeout} seconds for discovery replies to request #{reqid}")

            loop do
              reply = client.receive(reqid)
              Log.debug("Got discovery reply from #{reply.payload[:senderid]}")
              hosts << reply.payload[:senderid]

              return hosts if limit > 0 && hosts.size == limit
            end
          end
        rescue Timeout::Error => e
        rescue Exception => e
          raise
        ensure
          client.unsubscribe("discovery", :reply)
        end

        hosts
      end
    end
  end
end
