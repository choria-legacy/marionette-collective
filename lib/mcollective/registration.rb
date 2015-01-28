module MCollective
  # Registration is implimented using a module structure and installations can
  # configure which module they want to use.
  #
  # We provide a simple one that just sends back the list of current known agents
  # in MCollective::Registration::Agentlist, you can create your own:
  #
  # Create a module in plugins/mcollective/registration/<yourplugin>.rb
  #
  # You can inherit from MCollective::Registration::Base in which case you just need
  # to supply a _body_ method, whatever this method returns will be send to the
  # middleware connection for an agent called _registration_
  module Registration
    require "mcollective/registration/base"
  end
end
