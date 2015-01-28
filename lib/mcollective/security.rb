module MCollective
  # Security is implimented using a module structure and installations
  # can configure which module they want to use.
  #
  # Security modules deal with various aspects of authentication and authorization:
  #
  # - Determines if a filter excludes this host from dealing with a request
  # - Serialization and Deserialization of messages
  # - Validation of messages against keys, certificates or whatever the class choose to impliment
  # - Encoding and Decoding of messages
  #
  # To impliment a new security class using SSL for example you would inherit from the base
  # class and only impliment:
  #
  # - decodemsg
  # - encodereply
  # - encoderequest
  # - validrequest?
  #
  # Each of these methods should increment various stats counters, see the default MCollective::Security::Psk module for examples of this
  #
  # Filtering can be extended by providing a new validate_filter? method.
  module Security
    require "mcollective/security/base"
  end
end
