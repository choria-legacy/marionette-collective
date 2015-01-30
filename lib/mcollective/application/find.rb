class MCollective::Application::Find<MCollective::Application
  description "Find hosts using the discovery system matching filter criteria"

  def main
    mc = rpcclient("rpcutil")

    starttime = Time.now

    nodes = mc.discover

    discoverytime = Time.now - starttime

    STDERR.puts if options[:verbose]

    nodes.each {|c| puts c}

    STDERR.puts "\nDiscovered %s nodes in %.2f seconds using the %s discovery plugin" % [nodes.size, discoverytime, mc.client.discoverer.discovery_method] if options[:verbose]

    nodes.size > 0 ? exit(0) : exit(1)
  end
end
