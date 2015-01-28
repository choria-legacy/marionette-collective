module MCollective
  # Connectors take care of transporting messages between clients and agents,
  # the design doesn't your middleware to be very rich in features.  All it
  # really needs is the ability to send and receive messages to named queues/topics.
  #
  # At present there are assumptions about the naming of topics and queues that is
  # compatible with Stomp, ie.
  #
  # /topic/foo.bar/baz
  # /queue/foo.bar/baz
  #
  # This is the only naming format that is supported, but you could replace Stomp
  # with something else that supports the above, see MCollective::Connector::Stomp
  # for the default connector.
  module Connector
    require "mcollective/connector/base"
  end
end
