A simple helper to assist with writing MCollective actions in PHP.

Given an action as below:

<pre>
action "echo" do
   validate :message, String

   implemented_by "/tmp/echo.php"
end
</pre>

The following PHP script will implement the echo action externally
replying with _message_ and _timestamp_

<pre>
&lt;?php
    require("mcollective_action.php");

    $mc = new MCollectiveAction();
    $mc->message = $mc->data["message"];
    $mc->timestamp = strftime("%c");
    $mc->info("some text to info log on the server");
?>
</pre>

Calling it with _mco rpc_ results in:

<pre>
$ mco rpc test echo message="hello world"
Determining the amount of hosts matching filter for 2 seconds .... 1

 * [ ============================================================> ] 1 / 1


nephilim.ml.org                         : OK
    {:message=>"hello world", :time=>"Tue Mar 15 19:20:53 +0000 2011"}
</pre>
