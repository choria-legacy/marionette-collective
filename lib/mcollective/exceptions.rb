module MCollective
# Exceptions for the RPC system
  class DDLValidationError<RuntimeError;end
  class ValidatorError<RuntimeError; end
  class ClientTimeoutError<RuntimeError; end
  class MsgDoesNotMatchRequestID < RuntimeError; end
  class MsgTTLExpired<RuntimeError;end
  class NotTargettedAtUs<RuntimeError;end
  class RPCError<StandardError;end
  class SecurityValidationFailed<RuntimeError;end

  class BackoffSuggestion<StandardError
    attr_reader :backoff

    def initialize(backoff = nil)
      @backoff = backoff
    end
  end

  class MessageNotReceived<BackoffSuggestion; end
  class UnexpectedMessageType<BackoffSuggestion; end

  class InvalidRPCData<RPCError;end
  class MissingRPCData<RPCError;end
  class RPCAborted<RPCError;end
  class UnknownRPCAction<RPCError;end
  class UnknownRPCError<RPCError;end
end
