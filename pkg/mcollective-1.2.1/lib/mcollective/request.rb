module MCollective
    # A simple container class for messages from the middleware.
    #
    # By design we put everything we care for in a payload of the message and
    # do not rely on any headers, special data formats etc as produced by the
    # middleware, using this abstraction means we can enforce that
    class Request
        attr_reader :payload

        def initialize(payload)
            @payload = payload
        end
    end
end
# vi:tabstop=4:expandtab:ai
