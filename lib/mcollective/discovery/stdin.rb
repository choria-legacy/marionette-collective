# discovers against stdin instead of the traditional network discovery
# the input must be a flat file with a node name per line which should match identities as configured,
# or it should be a json string as output by the -j option of mco rpc
require 'mcollective/rpc/helpers'

module MCollective
  class Discovery
    class Stdin
      def self.discover(filter, timeout, limit=0, client=nil)
        unless client.options[:discovery_options].empty?
          type = client.options[:discovery_options].first.downcase
        else
          type = 'auto'
        end

        discovered = []

        file = STDIN.read

        if file =~ /^\s*$/
              raise("data piped on STDIN contained only whitespace - could not discover hosts from it.")
        end

        if type == 'auto'
          if file =~ /^\s*\[/
            type = 'json'
          else
            type = 'text'
          end
        end

        if type == 'json'
          hosts = MCollective::RPC::Helpers.extract_hosts_from_json(file)
        elsif type == 'text'
          hosts = file.split("\n")
        else
          raise("stdin discovery plugin only knows the types auto/text/json, not \"#{type}\"")
        end

        hosts.map do |host|
          raise 'Identities can only match /\w\.\-/' unless host.match(/^[\w\.\-]+$/)
          host
        end

        # this plugin only supports identity filters, do regex matches etc against
        # the list found in the flatfile
        unless filter["identity"].empty?
          filter["identity"].each do |identity|
            identity = Regexp.new(identity.gsub("\/", "")) if identity.match("^/")

            if identity.is_a?(Regexp)
              discovered = hosts.grep(identity)
            elsif hosts.include?(identity)
              discovered << identity
            end
          end
        else
          discovered = hosts
        end

        discovered
      end
    end
  end
end

