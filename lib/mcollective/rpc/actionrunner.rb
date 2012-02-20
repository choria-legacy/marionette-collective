module MCollective
  module RPC
    # A helper used by RPC::Agent#implemented_by to delegate an action to
    # an external script.  At present only JSON based serialization is
    # supported in future ones based on key=val pairs etc will be added
    #
    # It serializes the request object into an input file and creates an
    # empty output file.  It then calls the external command reading the
    # output file at the end.
    #
    # any STDERR gets logged at error level and any STDOUT gets logged at
    # info level.
    #
    # It will interpret the exit code from the application the same way
    # RPC::Reply#fail! and #fail handles their codes creating a consistent
    # interface, the message part of the fail message will come from STDERR
    #
    # Generally externals should just exit with code 1 on failure and print to
    # STDERR, this is exactly what Perl die() does and translates perfectly
    # to our model
    #
    # It uses the MCollective::Shell wrapper to call the external application
    class ActionRunner
      attr_reader :command, :agent, :action, :format, :stdout, :stderr, :request

      def initialize(command, request, format=:json)
        @command = command
        @agent = request.agent
        @action = request.action
        @format = format
        @request = request
        @stdout = ""
        @stderr = ""
      end

      def run
        unless canrun?(command)
          Log.warn("Cannot run #{to_s}")
          raise RPCAborted, "Cannot execute #{to_s}"
        end

        Log.debug("Running #{to_s}")

        request_file = saverequest(request)
        reply_file = tempfile("reply")
        reply_file.close

        runner = shell(command, request_file.path, reply_file.path)

        runner.runcommand

        Log.debug("#{command} exited with #{runner.status.exitstatus}")

        stderr.each_line {|l| Log.error("#{to_s}: #{l.chomp}")} unless stderr.empty?
        stdout.each_line {|l| Log.info("#{to_s}: #{l.chomp}")} unless stdout.empty?

        {:exitstatus => runner.status.exitstatus,
          :stdout     => runner.stdout,
          :stderr     => runner.stderr,
          :data       => load_results(reply_file.path)}
      ensure
        request_file.close! if request_file.respond_to?("close!")
        reply_file.close! if reply_file.respond_to?("close")
      end

      def shell(command, infile, outfile)
        env = {"MCOLLECTIVE_REQUEST_FILE" => infile,
          "MCOLLECTIVE_REPLY_FILE"   => outfile}

        Shell.new("#{command} #{infile} #{outfile}", :cwd => Dir.tmpdir, :stdout => stdout, :stderr => stderr, :environment => env)
      end

      def load_results(file)
        Log.debug("Attempting to load results in #{format} format from #{file}")

        data = {}

        if respond_to?("load_#{format}_results")
          tempdata = send("load_#{format}_results", file)

          tempdata.each_pair do |k,v|
            data[k.to_sym] = v
          end
        end

        data
      rescue Exception => e
        {}
      end

      def load_json_results(file)
        return {} unless File.readable?(file)

        JSON.load(File.read(file))
      rescue JSON::ParserError
        {}
      end

      def saverequest(req)
        Log.debug("Attempting to save request in #{format} format")

        if respond_to?("save_#{format}_request")
          data = send("save_#{format}_request", req)

          request_file = tempfile("request")
          request_file.puts data
          request_file.close
        end

        request_file
      end

      def save_json_request(req)
        req.to_json
      end

      def canrun?(command)
        File.executable?(command)
      end

      def to_s
        "#{agent}##{action} command: #{command}"
      end

      def tempfile(prefix)
        Tempfile.new("mcollective_#{prefix}", Dir.tmpdir)
      end
    end
  end
end
