module MCollective
  class CodedError<RuntimeError
    attr_reader :code, :args, :log_level, :default

    def initialize(msgid, default, level=:debug, args={})
      @code = msgid
      @log_level = level
      @args = args
      @default = default

      msg = Util.t(@code, {:default => default}.merge(@args))

      super(msg)
    end

    def set_backtrace(trace)
      super
      log(@log_level)
    end

    def log(level, log_backtrace=false)
      Log.logexception(@code, level, self, log_backtrace)
    end
  end

  # Exceptions for the RPC system
  class DDLValidationError<CodedError;end
  class ValidatorError<RuntimeError; end
  class MsgDoesNotMatchRequestID < RuntimeError; end
  class MsgTTLExpired<RuntimeError;end
  class NotTargettedAtUs<RuntimeError;end
  class RPCError<StandardError;end
  class SecurityValidationFailed<RuntimeError;end

  class InvalidRPCData<RPCError;end
  class MissingRPCData<RPCError;end
  class RPCAborted<RPCError;end
  class UnknownRPCAction<RPCError;end
  class UnknownRPCError<RPCError;end
end
