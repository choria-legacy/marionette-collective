#!/usr/bin/ruby

# A very simple demonstration of writing a REST server
# for Simple RPC clients that takes requests over HTTP
# and returns results as JSON structures.

require 'rubygems'
require 'sinatra'
require 'mcollective'
require 'json'

include MCollective::RPC

get '/mcollective/:agent/:action/*' do
    mc = rpcclient(params[:agent])
    mc.discover

    arguments = {}

    # split up the wildcard params into key=val pairs and 
    # build the arguments hash
    params[:splat].each do |arg|
        arguments[$1.to_sym] = $2 if arg =~ /^(.+?)=(.+)$/
    end

    JSON.dump(mc.send(params[:action], arguments))
end

