#!/usr/bin/env ruby

require 'rubygems'
require 'facter'
require 'passmakr'

Facter.reset
@facts = Facter.to_hash

def configure_mcollective(server, mcollective_password, psk=nil)
	unless psk
		pw = Passmakr.new(:phonemic, 8)
		psk = pw.password[:string]
	end


	["server", "client"].each do |cfgfile|
		templ = File.readlines("/etc/mcollective/#{cfgfile}.cfg.templ")

		File.open("/etc/mcollective/#{cfgfile}.cfg", "w") do |f|
			templ.each do |l|
				l.gsub!("@@hostname@@", @facts["hostname"])
				l.gsub!("@@server@@", server)
				l.gsub!("@@psk@@", psk)
				l.gsub!("@@mcollective_password@@", mcollective_password)

				f.puts l
			end
		end
	end

	puts("mcollective_psk=#{psk}") if @facts["mcollective"] == "server"
end

def configure_activemq(mcollective_password)
	templ = File.readlines("/etc/activemq/activemq.xml.templ")

	File.open("/etc/activemq/activemq.xml", "w") do |f|
		templ.each do |l|
			l.gsub!("@@mcollective_password@@", mcollective_password)

			f.puts l
		end
	end
end

if @facts.include?("mcollective")
	mcollective_type = @facts["mcollective"]

	if mcollective_type == "server"
		puts("Configuring MCollective as a server...")

		pw = Passmakr.new(:phonemic, 8)
		mcollective_password = pw.password[:string]

		puts("\n\n======= User Data for nodes ======")
		puts("mcollective=#{@facts['ipaddress']}")
		puts("mcollective_password=#{mcollective_password}")

		configure_mcollective("localhost", mcollective_password)
		configure_activemq(mcollective_password)
		puts("==================================")

		puts;puts

		system("/etc/init.d/activemq restart")

		puts("\nSleeping 10 seconds...")
		sleep 10

		system("cp /root/mcollective-plugins-read-only/agent/registration-monitor/registration.rb /usr/libexec/mcollective/mcollective/agent/")

		puts("Starting MCollective....")
		system("/etc/init.d/mcollective restart")
	elsif mcollective_type =~ /\d+\.\d+\.\d+\.\d+/
		unless @facts.include?("mcollective_password") && @facts.include?("mcollective_psk")
			STDERR.puts("mcollective_password and mcollective_psk user data was not set")
			exit 1
		end

		puts("Configuring MCollective as a node with server @ #{mcollective_type}...")

		mcollective_password = @facts["mcollective_password"]
		mcollective_psk = @facts["mcollective_psk"]

		configure_mcollective(mcollective_type, mcollective_password, mcollective_psk)
		system("/etc/init.d/mcollective restart")

		system("cp /usr/local/etc/mcollective-node.motd /etc/motd")
	end
else
	STDERR.puts("Please set mcollective=server|1.2.3.4 user data")
	exit 1
end
