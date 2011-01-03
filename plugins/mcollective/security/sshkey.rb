require "rubygems"
gem "sshkeyauth", ">= 0.0.4"

require "ssh/key/signer"
require "ssh/key/verifier"
require "etc"

module MCollective
    module Security
        # A security plugin for MCollective that uses ssh keys for message
        # signing and verification
        #
        # For clients (things initiating RPC calls):
        # * Message signing will use your ssh-agent.
        # * Message verification is done using the public key of the host that
        #   sent the message. This means you have to have the public key known
        #   before you can verify a message. Generally, this is your
        #   ~/.ssh/known_hosts file, but we invoke 'ssh-keygen -F <host>'
        #   The 'host' comes from the SimpleRPC senderid (defaults to the
        #   hostname)
        #
        #   Clients identify themselves with the RPC 'callerid' as your current
        #   user (via Etc::getlogin)
        #
        # For nodes/agents:
        # * Message signing uses the value of 'plugin.sshkey' in server.cfg.
        #   I recommend you use the path of your host's ssh rsa key, for example:
        #   /etc/ssh/ssh_host_rsa_key
        # * Message verification uses your user's authorized_keys file. The 'user'
        #   comes from the RPC 'callerid' field. This user must exist on your
        #   node host
        #
        # In cases of configurable paths, like the location of your authorized_keys
        # file, the 'sshkeyauth' library will try to parse it from the
        # sshd_config file (defaults to /etc/ssh/sshd_config)
        #
        # Since there is no challenge-reponse in MCollective RPC, we can't emulate
        # ssh's "try each key until one is accepted" method. Instead, we will
        # sign each method with *all* keys in your agent and the receiver will
        # try to verify against any of them.
        #
        # Serialization uses Marshal.
        #
        # NOTE: This plugin should be considered experimental at this point as it has
        #       a few gotchas and drawbacks.
        #
        #       * Nodes cannot easily send messages now, this means registration is
        #         not supported
        #       * Automated systems that wish to manage a collective with this plugin
        #         will somehow need access to ssh agents, this can insecure and
        #         problematic in general.
        #
        # We're including this plugin as an early preview of what is being worked on
        # in order to solicit feedback.
        #
        # Configuration:
        #
        # For clients:
        #   securityprovider = sshkey
        #
        # For nodes:
        #   securityprovider = sshkey
        #   plugin.sshkey = /etc/ssh/ssh_host_rsa_key
        class Sshkey < Base
            # Decodes a message by unserializing all the bits etc
            # TODO(sissel): refactor this into Base?
            def decodemsg(msg)
                body = Marshal.load(msg.payload)

                if validrequest?(body)
                    body[:body] = Marshal.load(body[:body])
                    return body
                else
                    nil
                end
            end

            # Encodes a reply
            def encodereply(sender, target, msg, requestid, requestcallerid=nil)
                serialized  = Marshal.dump(msg)
                digest = makehash(serialized)

                Log.debug("Encoded a message with hash #{digest} for request #{requestid}")

                Marshal.dump({:senderid => @config.identity,
                              :requestid => requestid,
                              :senderagent => sender,
                              :msgtarget => target,
                              :msgtime => Time.now.to_i,
                              :hash => digest,
                              :body => serialized})
            end

            # Encodes a request msg
            def encoderequest(sender, target, msg, requestid, filter={})
                serialized = Marshal.dump(msg)
                digest = makehash(serialized)

                Log.debug("Encoding a request for '#{target}' with request id #{requestid}")
                request = {:body => serialized,
                           :hash => digest,
                           :senderid => @config.identity,
                           :requestid => requestid,
                           :msgtarget => target,
                           :filter => filter,
                           :msgtime => Time.now.to_i}

                # if we're in use by a client add the callerid to the main client hashes
                request[:callerid] = callerid if @initiated_by == :client

                Marshal.dump(request)
            end

            def callerid
                return Etc.getlogin
            end

            # Checks the md5 hash in the request body against our psk, the
            # request sent for validation
            # should not have been deserialized already
            def validrequest?(req)
                Log.info "Caller id: #{req[:callerid]}"
                Log.info "Sender id: #{req[:senderid]}"
                message = req[:body]

                #@log.info req.awesome_inspect
                identity = (req[:callerid] or req[:senderid])
                verifier = SSH::Key::Verifier.new(identity)

                Log.info "Using name '#{identity}'"

                # If no callerid, this is a 'response' message and we should
                # attempt to authenticate using the senderid (hostname, usually)
                # and that ssh key in known_hosts.
                if !req[:callerid]
                  # Search known_hosts for the senderid hostname
                  verifier.add_key_from_host(identity)
                  verifier.use_agent = false
                  verifier.use_authorized_keys = false
                end

                signatures = Marshal.load(req[:hash])
                if verifier.verify?(signatures, req[:body])
                    @stats.validated
                    return true
                else
                    @stats.unvalidated
                    raise(SecurityValidationFailed, "Received an invalid signature in message")
                end
            end

            private
            # Signs a message. If 'public.sshkey' is set, then we will sign
            # with only that key. Otherwise, we will sign with your ssh-agente.
            def makehash(body)
                signer = SSH::Key::Signer.new
                if @config.pluginconf["sshkey"]
                    signer.add_key_file(@config.pluginconf["sshkey"])
                    signer.use_agent = false
                end
                signatures = signer.sign(body).collect { |s| s.signature }
                return Marshal.dump(signatures)
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
