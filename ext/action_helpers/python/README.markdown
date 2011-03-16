A simple helper to assist with writing MCollective actions in Python.

Given an action as below:

<pre>
action "echo" do
   validate :message, String

   implemented_by "/tmp/echo.py"
end
</pre>

The following Python script will implement the echo action externally
replying with _message_ and _timestamp_

<pre>
#!/bin/env python
import mcollectiveah
import time

mc = mcollectiveah.MCollectiveAction()
mc.reply['message'] = mc.request['message']
mc.reply['timestamp'] = time.strftime("%c")
mc.reply['info'] = "some text to info log in the server"
</pre>

Calling it with _mco rpc_ results in:

<pre>
$ mco rpc test echo message="hello world"
Determining the amount of hosts matching filter for 2 seconds .... 1

 * [ ============================================================> ] 1 / 1


nephilim.ml.org                         : OK
    {:message=>"hello world", :time=>"Tue Mar 15 19:20:53 +0000 2011"}
</pre>
