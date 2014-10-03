module MCollective
  module Security
    # Use ActiveMQ authenticated JMSXUserID for auhtorization. This enables to 
    # only use Puppet certificates an
    #
    # * add "populateJMSXUserID='true'" to "<broker ... >" in activemq.xml
    #   this sets the message header "JMXUserID"
    # * enable JaasCertificateAuthenticationPlugin (or any other) in activemq.xml 
    #   which sets username a
    # * remove the simpleAutehntication block in activemq.xml (not tried to use both)
    # * use Puppet to deploy ActiveMQ JAAS user/group config files 
    #   * /etc/activemq/login.config
    #   * /etc/activemq/users.properties (on edit no restart of activemq needed)
    #   * /etc/activemq/groups.properties (on edit no restart of activemq needed)
    #   * ensure groups have correct access rights in simpleAuthorization config (activemq.xml)
    # * set "plugin.jmsxuserid" to ActiveMQ username 
    #   * if using JaasCertificateAuthenticationPlugin: the username is not the one 
    #     from users.properties but the certificate CN=*. The username from users.properties
    #     seems to be only used in groups.properties.
    # 
    # Link to more information about Jaas Certificate Authentication Plugin:
    # https://access.redhat.com/documentation/en-US/Fuse_MQ_Enterprise/7.1/html/Security_Guide/files/Auth-JAAS-CertAuthentPlugin.html
    class Jmsxuserid < Base

      def decodemsg(msg)
        body = Marshal.load(msg.payload)
        should_process_msg?(msg, body[:requestid])

        if validrequest?(msg.headers['JMSXUserID'], body[:callerid])
	  body[:body] = Marshal.load(body[:body])
          return body
        else
          nil
        end
      end

      def encodereply(sender, msg, requestid, requestcallerid=nil)
        serialized = Marshal.dump(msg)
        reply = create_reply(requestid, sender, serialized))
        reply[:callerid] = callerid
        Marshal.dump(reply)
      end

      # Just pass to create_request
      def encoderequest(identity, payload, requestid, filter, target_agent, target_collective, ttl=60)
        payload_serialized = Marshal.dump(payload)
        req = create_request(requestid, filter, payload_serialized, @initiated_by, target_agent, target_collective, ttl)
	Marshal.dump(req)
      end

      # 
      def validrequest?(msg_jmsxuserid=nil, payload_callerid=nil)
        Log.debug("Compare messages JMSXUserID=#{msg_jmsxuserid} to payload callerid=#{payload_callerid}")
        if msg_jmsxuserid.nil? or msg_jmsxuserid.empty?
          @stats.unvalidated
          raise(SecurityValidationFailed, "Message header 'JMSXUserID' is empty. Please check your ActiveMQ configuration.")
        elsif "jmsxuserid=#{msg_jmsxuserid}" != payload_callerid
          @stats.unvalidated
	  Log.warn("Message header 'JMSXUserID' (value: #{msg_jmsxuserid}) and callerid (value: #{payload_callerid}) of payload do not match. Setting plugin.jmsxuserid has to match JMSXUserID of ActiveMQ")
          raise(SecurityValidationFailed, "Message header 'JMSXUserID' (value: #{msg_jmsxuserid}) and callerid (value: #{payload_callerid}) of payload do not match. Setting plugin.jmsxuserid has to match JMSXUserID of ActiveMQ")
        else
          @stats.validated
          true
        end
      end

      def callerid
        "jmsxuserid=#{get_jmsxuserid}"
      end

      def get_jmsxuserid
        if ENV.include?("MCOLLECTIVE_JMSXUSERID")
          jmsxuserid = ENV["MCOLLECTIVE_JMSXUSERID"]
        else
          raise("No plugin.jmsxuserid configuration option specified and no env MCOLLECTIVE_JMSXUSERID set") unless @config.pluginconf.include?("jmsxuserid")
          jmsxuserid = @config.pluginconf["jmsxuserid"]
        end
      end

    end
  end
end

