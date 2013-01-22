module MCollective
  module Translatable
    def t(msgid, default, args={})
      Util.t(msgid, {:default => default}.merge(args))
    end

    def log_code(msgid, default, level, args={})
      msg = "%s: %s" % [msgid, Util.t(msgid, {:default => default}.merge(args))]

      Log.log(level, msg, File.basename(caller[1]))
    end

    def raise_code(msgid, default, level, args={})
      exception = CodedError.new(msgid, default, level, args)
      exception.set_backtrace caller

      raise exception
    end

    def logexception(msgid, default, level, e, backtrace=false)
      Log.logexception(msgid, level, e, backtrace)
    end
  end
end
