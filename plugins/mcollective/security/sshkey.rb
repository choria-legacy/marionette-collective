require "rubygems"
gem "sshkeyauth", ">= 0.0.4"
require "ssh/key/signer"
require "ssh/key/verifier"
require "etc"

module MCollective
    module Security
        # Impliments message authentication using digests and shared keys
        # 
        # You should configure a psk in the configuration file and all requests
        # will be validated for authenticity with this.
        #
        # Serialization uses Marshal, this is the default security module that is
        # supported out of the box.
        #
        # Validation is as default and is provided by MCollective::Security::Base
        class Sshkey < Base
            # Decodes a message by unserializing all the bits etc, it also validates
            # it as valid using the psk etc
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
            def encodereply(sender, target, msg, requestid, filter={})
                serialized  = Marshal.dump(msg)
                digest = makehash(serialized)
    
                @log.debug("Encoded a message with hash #{digest} for request #{requestid}")
    
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
    
                @log.debug("Encoding a request for '#{target}' with request id #{requestid}")
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
                @log.info "Caller id: #{req[:callerid]}"
                @log.info "Sender id: #{req[:senderid]}"
                message = req[:body]

                #@log.info req.awesome_inspect
                identity = (req[:callerid] or req[:senderid])
                verifier = SSH::Key::Verifier.new(identity)

                @log.info "Using name '#{identity}'"

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
                    raise("Received an invalid signature in message")
                end
            end
    
            private
            # Retrieves the value of plugin.psk and builds a hash with it and
            # the passed body
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
