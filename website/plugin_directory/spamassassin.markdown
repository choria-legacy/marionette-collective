---
layout: default
title: "MCollective Plugin: SpamAssassin"
---


Introduction
------------

An agent to handle Spam Assassin tasks such as compiling a ruleset, restarting the service, viewing the service status + compiled ruleset modified timestamp, checking for ruleset syntax errors, and executing an sa-update. Alternatively, the 'full' command will execute an update, compilation, and restart all at once.

Installation
------------

The source for the plugin is [GitHub](https://github.com/mstanislav/mCollective-Agents/tree/master/spamassassin)


Configuration
-------------

Below are the currently available plugin configuration options:

<pre>
plugin.spamassassin.compiled_ruleset = /var/lib/spamassassin/compiled/5.008/3.002005/Mail/SpamAssassin/CompiledRegexps/body_0.pm
</pre>

Usage
-----
### Status

<pre>
# mc-spamassassin -W "purpose=asav" status
asav01.example.com                      RUNNING, COMPILED RULESET MON JAN 17 15:14:03 -0600 2011
asav02.example.com                      RUNNING, COMPILED RULESET MON JAN 17 15:18:28 -0600 2011
asav03.example.com                	    RUNNING, COMPILED RULESET MON JAN 17 15:20:53 -0600 2011
asav04.example.com                	    RUNNING, COMPILED RULESET MON JAN 17 15:27:06 -0600 2011
asav05.example.com                	    RUNNING, COMPILED RULESET MON JAN 17 15:24:07 -0600 2011

Finished processing 5 / 5 hosts in 380.58 ms
</pre>

### Update

<pre>
# mc-spamassassin -W "purpose=asav" update
asav02.example.com                       NO UPDATES FOUND
asav03.example.com                       NO UPDATES FOUND
asav05.example.com                	     NO UPDATES FOUND
asav04.example.com                	     NO UPDATES FOUND
asav01.example.com                       NO UPDATES FOUND

Finished processing 5 / 5 hosts in 956.66 ms
</pre>

### Compile

<pre>
# mc-spamassassin -W "purpose=asav" compile
asav05.example.com                	     OK
asav03.example.com                       OK
asav02.example.com                       OK
asav04.example.com                	     OK
asav01.example.com                       OK

Finished processing 5 / 5 hosts in 61450.94 ms
</pre>

### Lint

<pre>
# mc-spamassassin -W "purpose=asav" lint
asav05.example.com                	     3 SYNTAX ERRORS
asav02.example.com                       SYNTAX OK
asav04.example.com                	     2 SYNTAX ERRORS
asav03.example.com                       SYNTAX OK
asav01.example.com                       SYNTAX OK

Finished processing 5 / 5 hosts in 5004.15 ms
</pre>

### Restart

<pre>
# mc-spamassassin -W "purpose=asav" restart
asav05.example.com                	     OK
asav04.example.com                	     OK
asav02.example.com                       OK
asav03.example.com                       OK
asav01.example.com                       OK

Finished processing 5 / 5 hosts in 5134.55 ms
</pre>

### Full

<pre>
# mc-spamassassin -W "purpose=asav" full
asav05.example.com                	     NO UPDATES FOUND, COMPILATION OK, RESTART OK
asav02.example.com                       NO UPDATES FOUND, COMPILATION OK, RESTART OK
asav04.example.com                	     NO UPDATES FOUND, COMPILATION OK, RESTART OK
asav03.example.com                       NO UPDATES FOUND, COMPILATION OK, RESTART OK
asav01.example.com                       NO UPDATES FOUND, COMPILATION OK, RESTART OK

Finished processing 5 / 5 hosts in 66339.50 ms
</pre>
