---
layout: default
title: Changelog
toc: false
---

## Version 2.8.x

|Date|Description|Ticket|
|----|-----------|------|
|2016/05/11|Release *2.8.9*||
|2016/05/03|Work around RuboCop parser change causing errors on non UTF-8 compliant strings|(#375)[https://github.com/puppetlabs/marionette-collective/pull/375]|
|2016/05/03|Pin rake to 10.4 required for running tests on ruby 1.8.7|(#375)[https://github.com/puppetlabs/marionette-collective/pull/375]|
|2016/02/25|Release *2.8.8*||
|2016/02/25|Fix dependency on aio for creating the pidfile directory|MCO-753|
|2016/02/18|Improve pidfile handling to avoid running multiple daemons|MCO-751|
|2016/02/18|Update build targets to LTS debian variants|MCO-634|
|2016/02/05|Update mco.bat file to allow for absence of CONFIG_FILE setting|MCO-748|
|2016/01/22|Add windows support to install.rb|MCO-745|
|2016/01/13|Release *2.8.7*||
|2015/12/17|Fix systemd logrotate unit|MCO-744|
|2015/12/16|Fix run helper for systems where the path to ruby binary includes spaces|MCO-742|
|2015/12/01|Fix negative data plugin comparisons|MCO-739|
|2015/09/15|Release *2.8.6*|MCO-726|
|2015/09/11|Fix solaris smf service manifest for aio|(#345)[https://github.com/puppetlabs/marionette-collective/pull/345]|
|2015/09/10|Release *2.8.5*|MCO-724|
|2015/08/25|Add condrestart to the suse init script for AIO|RE-11690|
|2015/08/21|Release *2.8.4*|MCO-706|
|2015/08/20|Revert RE-5032|MCO-705|
|2015/08/18|Release *2.8.3*|MCO-689|
|2015/08/05|Add solaris smf service for AIO|MCO-687|
|2015/07/17|Fully qualify the label in the osx mco plist|RE-5032|
|2015/07/13|Set character encoding in the OSX plist|(#326)[https://github.com/puppetlabs/marionette-collective/pull/326]|
|2015/07/03|Fix documentation links to use https|DOCS-2092|
|2015/06/05|Add `mco describe_filter` application|MCO-668|
|2015/06/05|Fix quote handling in compound query language|MCO-668|
|2015/06/04|Add acceptance tests|MCO-671|
|2015/05/19|Release *2.8.2*|MCO-648|
|2015/05/12|Do not build for debian stable or testing (target codenames instead)|MCO-665|
|2015/05/08|Exit non-zero when `mco` is called with a non-existent subcommand|MCO-640|
|2015/05/08|Add legacy `libdir` settings to aio sample config|MCO-641|
|2015/05/08|Downgrade warning on absent `libdir`|MCO-647|
|2015/05/04|Add OSX plist for AIO|MCO-646|
|2015/04/23|Drop lucid from build targets|MCO-638|
|2015/04/13|Drop fedora 19 from build targets|MCO-633|
|2015/03/22|Update AIO SUSE init script|RE-3977|
|2015/03/11|Release *2.8.1*|MCO-601|
|2015/03/05|Maintain version number in-tree|MCO-617|
|2015/02/18|Use updated AIO paths|MCO-594|
|2015/02/10|Fix AIO debian condrestart action|MCO-591|
|2015/02/05|Fix problems with 2.8.0 gem loading|MCO-587|
|2015/02/04|Release *2.8.0*|MCO-561|
|2015/02/02|Add AIO init scripts to ext/aio|MCO-555|
|2015/02/02|Move core plugins into sitelibdir|MCO-583|
|2015/01/29|Prefer configuration files from AIO paths|MCO-560|
|2015/01/29|Use $LOAD_PATH for loading plugins|MCO-315|
|2015/01/28|Replace uses of `autoload` with `require`|MCO-580|
|2015/01/21|Fix `mco facts` in absence of fact|MCO-558|
|2015/01/07|Ensure rubocop failures fail the build|MCO-519|
|2014/12/19|Fix powershell exit code interactions|MCO-550|


## Version 2.7.x

|Date|Description|Ticket|
|----|-----------|------|
|2014/12/02|Release *2.7.0*|MCO-525|
|2014/11/24|Revisit STOMP 1.1 heart-beat defaults|MCO-522|
|2014/11/18|Log the senderid of messages at debug|MCO-521|
|2014/11/11|Add a --connection-timeout to the client options|MCO-464|
|2014/11/11|Add search of `$libdir/mcollective/agent/$agent/$action` to `implemented_by`|MCO-466|
|2014/11/10|`mco plugin package` support for 'lib' layout|MCO-314|
|2014/10/28|Add rubocop style checks to the codebase|MCO-136|
|2014/10/22|Expose target collective to custom discovery plugins|MCO-456|
|2014/10/13|Make windows service_manager.rb helper more vigorous in finding ruby|MCO-465|
|2014/10/02|Reraise exceptions caught by the runner thread in the main thread|MCO-475|
|2014/10/01|Add a collective data plugin|MCO-472|
|2014/10/01|Update windows scripts to pass --daemonize to daemon|MCO-474|
|2014/09/20|Report the version of stomp gem at startup|MCO-470|
|2014/09/19|Removed vendoring of the json gem|MCO-457|


## Version 2.6.x

|Date|Description|Ticket|
|----|-----------|------|
|2014/10/29|Release *2.6.1*|MCO-495|
|2014/10/23|Disable SSLv2 and SSLv3 protocols by default|MCO-489|
|2014/10/16|Expose SSL cipher selection via connector settings|MCO-486|
|2014/08/28|Release *2.6.0*|MCO-422|
|2014/08/20|Fix a race condition in type validator plugin loader|MCO-453|
|2014/08/12|Use a distinct reply queue per request|MCO-443|
|2014/08/07|Add `soft_shutdown_timeout` option|MCO-243|
|2014/08/06|Add documentation of heartbeat options to the connector pages|MCO-175|
|2014/08/01|Move signal handling into threads (ruby 2 compatibility)|MCO-421|
|2014/08/01|Allow LC\_ALL environment variable to be unset|MCO-156|
|2014/08/01|Add `discovery_timeout` to the configuration file|MCO-193|
|2014/08/01|Add `registration_splay` configuration option|MCO-272|
|2014/07/31|Allow for agent loading to be globally defaulted|MCO-408|
|2014/07/31|Change the 'expired message' message to indicate the message is being discarded|MCO-418|
|2014/07/31|Allow the --batch flag to specify percentages|MCO-68|
|2014/07/31|Reopen logfiles on SIGWINCH|MCO-328|
|2014/07/31|Add --sort option to rpc clients|MCO-83|
|2014/07/31|Dynamically decide number of columns for output|PR#215|
|2014/07/31|Specify the --daemonize option in sample init scripts|MCO-416|
|2014/07/29|Allow `limit_targets` to be reset|MCO-93|
|2014/07/29|Fixed rabbitmq reply-to under `use_reply_exchange`|MCO-351|
|2014/07/29|Reworked examples of catching uncatchable errors|MCO-411|
|2014/07/23|Make the base64 decoder more strict|MCO-293|
|2014/07/22|Add support for structured facts|MCO-363|
|2014/07/18|Fix `call_agent_batched` to work with activerecord|MCO-205|
|2014/07/18|Fix rpc response processing for bad replies|MCO-264|
|2014/07/17|Fix direct addressing regression introduced in MCO-360|MCO-410|
|2014/07/17|Require connector plugins to have ddls|MCO-407|
|2014/07/17|Add ddls to `activemq` and `rabbitmq` connectors|MCO-406|
|2014/07/16|Fix halt\_code to return the correct exitcode for `mco ping`|MCO-199|
|2014/07/16|Remove all reference to the 'mcollective' agent|MCO-360|
|2014/07/01|Add --no-daemonize and --daemonize option to mcollectived|MCO-181|
|2014/05/21|Fix a url in the solaris readme|MCO-186|


## Version 2.5.x

|Date|Description|Ticket|
|----|-----------|------|
|2014/07/15|Release *2.5.3*|MCO-368|
|2014/06/20|Address potential flaw in aes security plugin.  CVE-2014-3251|MCO-329|
|2014/05/30|Fix data plugin load ordering|MCO-346|
|2014/06/10|Release *2.5.2*|MCO-331|
|2014/05/27|Remove '.' from ruby `$LOAD_PATH` CVE-2014-3248|MCO-311|
|2014/05/14|Release *2.5.1*|MCO-295|
|2014/05/12|Allow stomp login/passcode to be optional|MCO-316|
|2014/05/02|Fix dependencies of rpms from `mco plugin package`|MCO-292|
|2014/05/01|Fix rpmbuild error in `mco plugin package`|MCO-285|
|2014/04/24|Stop install mc-call-agent|MCO-266|
|2014/04/24|Improve line parsing in flatfile discovery|MCO-262|
|2014/04/23|Release *2.5.0*|MCO-246|
|2014/04/23|Deprecate Runner#run method|MCO-265|
|2014/04/23|Drop ubuntu 13.04 (raring ringtail) from the supported package builds|MCO-263|
|2014/04/17|Add ubuntu 14.04 (trusty tahir) to the supported package builds|MCO-189|
|2014/04/10|Release *2.5.0-rc1*|MCO-226|
|2014/04/10|Refactor the runner class|MCO-221|
|2014/04/04|Update rubygems requirement to 1.3.7 or greater|MCO-188|
|2014/04/02|Move exception classes from lib/mcollective.rb to lib/mcollective/exceptions.rb|MCO-215|
|2014/03/26|Plugin plugin - add dist macro to Release field|MCOP-17|
|2014/03/12|Implements exponential back-off at the connector level|MCO-192|
|2014/02/28|Log reciept and contents of non-MESSAGE STOMP frames|MCO-191|
|2014/02/25|Connectors should not suggest STOMP 1.1 heartbeats if the gem cannot support them|MCO-198|
|2014/02/13|Remove Fedora 18 from build targets|MCO-166|

## Version 2.4.x

|Date|Description|Ticket|
|----|-----------|------|
|2014/02/10|*Release 2.4.1*|MCO-180|
|2014/02/10|Remove reference to package iteration in #package_information|MCO-179|
|2014/02/07|Update documentation to note that `plugin.rabbitmq.use_reply_exchange` should work from 2.4.1|MCO-174|
|2014/01/30|Improve logging when connector fails to connect|MCO-173|
|2014/01/29|Fix `plugin.rabbitmq.use_reply_exchange` subscription behavior|MCO-172|
|2014/01/23|*Release 2.4.0*|MCO-168|
|2014/01/16|*Release 2.4.0-rc2*|MCO-162|
|2014/01/16|MCollective service doesn't exit on Windows|MCO-158|
|2014/01/09|*Release 2.4.0-rc1*|MCO-152|
|2014/01/08|Turned use of removed options into warnings|MCO-151|
|2014/01/08|Removed i18n spike (#18863)|MCO-138|
|2014/01/07|Fixed a spurious warning in 'mco ping'|MCO-146|
|2014/01/07|Config class does not parse fixnum config parameters correctly|MCO-97|
|2014/01/06|deprecate and remove flattened output|MCO-84|
|2013/12/19|Make audit plugin log output match standard format|MCO-142|
|2013/11/07|Add a modulepackage target to the plugin packager|23099|
|2013/11/06|Fix possible thread leak in Shell|23090|
|2013/11/06|Add a timeout option for system commands|22114|
|2013/11/05|Redo the packaging of mcollective|17067|
|2013/10/30|Add rabbitmq federation support with `plugin.rabbitmq.use_reply_exchange`|22603|
|2013/10/30|Update rabbitmq connector documentation for recent version of rabbitmqadmin|19537|
|2013/10/17|mcollective service does not gracefully exit on windows|20467|
|2013/10/16|Add option to thread client|21910|
|2013/10/16|Publishing time should not be part of the request time|21910|
|2013/10/11|Add a stdin discovery method|22061|
|2013/10/08|Plugin packager doesn't apply --pluginversion option|22790|
|2013/10/07|Mcollective plugins cannot express dependencies|22361|
|2013/10/03|Ability to retrieve multiple facts through rpcutil|21788|
|2013/10/01|Fix packaging for debain/ubuntu with ruby 1.9|16572|
|2013/09/27|Fix buildmacpkg|16786|
|2013/09/27|Fix --nodes 'nodefile' on ruby 1.9.3|22720|
|2013/09/25|MCO Plugin Packager produces more than one source artifact|22316|
|2013/09/06|Fix directed request on subcollectives with rabbit connector|21755|
|2013/08/19|add an install.rb file to mcollective|22220|
|2013/08/02|Support Stomp 1.1 with RabbitMQ and ActiveMQ|15182|
|2013/07/31|Surpress Errno::ESRCH info messages when running shell commands|21779|
|2013/07/03|Improve error reporting when requesting docs for a non existing plugin|21429|
|2013/07/03|Support aggregate plugins in 'mco plugin doc'|18414|
|2013/07/03|Allow the ActiveMQ and RabbitMQ SSL cert paths to be set using environment variables|20550|
|2013/06/23|Gracefully handle whitespaces in the config file before config keys|21407|
|2013/06/19|Ensure the line numbers are printed correctly on both Windows and Unix|20506|
|2013/06/19|Remove the rpchelptemplate and helptemplatedir options|20714|
|2013/06/18|Correctly detect Windows absolute paths|21251|
|2013/06/10|Fix and centralize handling of boolean values for settings|19751|
|2013/06/06|Clone the default values from the DDL to avoid accidental modifications to the cached DDL file|21104|
|2013/06/05|Filter methods on the RPC Client are now idempotent|20233|
|2013/06/04|run() call in an agent can return incorrect Process::Status|17667|
|2013/06/03|Improve debian dependencies so packages can be rebuilt in a chroot|20950|
|2013/05/28|Set expire headers in the ActiveMQ and RabbitMQ message headers|19905|
|2013/05/10|Correctly detect version differences in semver version where the path level is greater 10|20661|
|2013/05/01|Improve behaviour of data matchers when return values are nil|20059|
|2013/04/29|Improve config defaults on windows machines|20388|
|2013/04/18|Enforce valid identity names in the file discovery method|20282|
|2013/04/11|Add direct addressing awareness to the fire and forget request mode|17930|
|2013/03/22|Remove the topicprefix, queueprefix and topicsep options|19673|
|2013/03/21|Remove the plugin.discovery.timeout setting as it's not relevant anymore|19694|
|2013/03/21|Improve error reporting from the rpc application in the light of direct_addressing|19827|
|2013/03/20|Fail with a friendly error message when no libdir is set|19752|
|2013/03/14|Change default RabbitMQ and ActiveMQ ports to 61613|19734|
|2013/03/13|Set correct reply-to headers in the RabbitMQ connector|17034|
|2013/03/12|Pre-populate the data from data plugins like agent replies|19564|
|2013/03/12|Explicitly include StringIO|19367|
|2013/03/12|Enable direct addressing by default|19665|
|2013/02/20|Fix error code collision on PLMC18|19366|
|2013/02/15|Validate arguments supplied to the RPC application and raise errors sooner|19181|

## Version 2.3.x

|Date|Description|Ticket|
|----|-----------|------|
|2014/01/08|Turned use of removed options into warnings|MCO-151|
|2014/01/08|Removed i18n spike (#18863)|MCO-138|
|2014/01/07|Fixed a spurious warning in 'mco ping'|MCO-146|
|2014/01/07|Config class does not parse fixnum config parameters correctly|MCO-97|
|2014/01/06|deprecate and remove flattened output|MCO-84|
|2013/12/19|Make audit plugin log output match standard format|MCO-142|
|*2013/11/07*|*Release 2.3.3*|23107|
|2013/11/07|Add a modulepackage target to the plugin packager|23099|
|2013/11/06|Fix possible thread leak in Shell|23090|
|2013/11/06|Add a timeout option for system commands|22114|
|2013/11/05|Redo the packaging of mcollective|17067|
|2013/10/30|Add rabbitmq federation support with `plugin.rabbitmq.use_reply_exchange`|22603|
|2013/10/30|Update rabbitmq connector documentation for recent version of rabbitmqadmin|19537|
|2013/10/17|mcollective service does not gracefully exit on windows|20467|
|2013/10/16|Add option to thread client|21910|
|2013/10/16|Publishing time should not be part of the request time|21910|
|2013/10/11|Add a stdin discovery method|22061|
|2013/10/08|Plugin packager doesn't apply --pluginversion option|22790|
|2013/10/07|Mcollective plugins cannot express dependencies|22361|
|2013/10/03|Ability to retrieve multiple facts through rpcutil|21788|
|2013/10/01|Fix packaging for debain/ubuntu with ruby 1.9|16572|
|2013/09/27|Fix buildmacpkg|16786|
|2013/09/27|Fix --nodes 'nodefile' on ruby 1.9.3|22720|
|2013/09/25|MCO Plugin Packager produces more than one source artifact|22316|
|2013/09/06|Fix directed request on subcollectives with rabbit connector|21755|
|2013/08/19|add an install.rb file to mcollective|22220|
|2013/08/02|Support Stomp 1.1 with RabbitMQ and ActiveMQ|15182|
|2013/07/31|Surpress Errno::ESRCH info messages when running shell commands|21779|
|*2013/07/11*|*Release 2.3.2*|21527|
|2013/07/03|Improve error reporting when requesting docs for a non existing plugin|21429|
|2013/07/03|Support aggregate plugins in 'mco plugin doc'|18414|
|2013/07/03|Allow the ActiveMQ and RabbitMQ SSL cert paths to be set using environment variables|20550|
|2013/06/23|Gracefully handle whitespaces in the config file before config keys|21407|
|2013/06/19|Ensure the line numbers are printed correctly on both Windows and Unix|20506|
|2013/06/19|Remove the rpchelptemplate and helptemplatedir options|20714|
|2013/06/18|Correctly detect Windows absolute paths|21251|
|2013/06/10|Fix and centralize handling of boolean values for settings|19751|
|2013/06/06|Clone the default values from the DDL to avoid accidental modifications to the cached DDL file|21104|
|2013/06/05|Filter methods on the RPC Client are now idempotent|20233|
|2013/06/04|run() call in an agent can return incorrect Process::Status|17667|
|2013/06/03|Improve debian dependencies so packages can be rebuilt in a chroot|20950|
|2013/05/28|Set expire headers in the ActiveMQ and RabbitMQ message headers|19905|
|2013/05/10|Correctly detect version differences in semver version where the path level is greater 10|20661|
|2013/05/01|Improve behaviour of data matchers when return values are nil|20059|
|2013/04/29|Improve config defaults on windows machines|20388|
|2013/04/18|Enforce valid identity names in the file discovery method|20282|
|2013/04/11|Add direct addressing awareness to the fire and forget request mode|17930|
|2013/03/22|Remove the topicprefix, queueprefix and topicsep options|19673|
|2013/03/21|Remove the plugin.discovery.timeout setting as it's not relevant anymore|19694|
|2013/03/21|Improve error reporting from the rpc application in the light of direct_addressing|19827|
|2013/03/20|Fail with a friendly error message when no libdir is set|19752|
|2013/03/14|Change default RabbitMQ and ActiveMQ ports to 61613|19734|
|2013/03/13|Set correct reply-to headers in the RabbitMQ connector|17034|
|2013/03/12|Pre-populate the data from data plugins like agent replies|19564|
|2013/03/12|Explicitly include StringIO|19367|
|2013/03/12|Enable direct addressing by default|19665|
|2013/02/20|Fix error code collision on PLMC18|19366|
|2013/02/15|Validate arguments supplied to the RPC application and raise errors sooner|19181|
|*2013/02/14*|*Release 2.3.1*|19265|
|2013/02/14|Initial work towards internationalization and online help|18663|
|2013/02/14|Update vendored JSON gem for CVE-2013-0269|19265|
|2013/02/13|Restore the ability to set a discovery timeout on a RPC client|19238|
|2013/02/12|Replace underscores in plugin names with dashes to keep Debian happy|19200|
|2013/02/12|Fix package building on certain Debian systems|19141|
|2013/02/12|Remove the stomp connector|19146|
|2013/02/07|Read the client config before trying to use any configuration options|19105|
|2013/01/22|When an argument fails to parse in the rpc application fail rather than continue with unintended consequences|18773|
|2013/01/22|The fix the *--no-response* argument to the rpc application that broke due to 18438|18513|
|2013/01/22|Set *=* dependencies on the various packages that form a plugin rather than *>=*|18758|
|2013/01/21|Improve presentation of the --help output for applications|18447|
|2013/01/21|When a request failed via *reply.fail*, only show the message and not the half built data|18434|
|*2013/01/10*|*Release 2.3.0*|18259|
|2013/01/10|Raise the correct exception when trying to access unknown data items in a Data results|18466|
|2013/01/10|Fix failing documentation generation for data plugins|18437|
|2013/01/09|Correctly support negative boolean flags declared as --[no]-foo|18438|
|2013/01/03|Add the package iteration number as a dependency for the common packages|18273|
|2012/12/21|The libdirs supplied in the config file now has to be absolute paths to avoid issues when daemonising|16018|
|2012/12/20|Logs the error and backtrace when an action fails|16414|
|2012/12/20|Display the values of :optional and :default in DDL generated help|16616|
|2012/12/20|Allow the query string for the get_data action in rpcutil to be 200 chars|18200|
|2012/12/19|Do not fail when packaging non-agent packages using custom paths|17281|
|2012/12/19|Require Ruby > 1.8 in the RPM specs for Ruby 1.9|17149|
|2012/12/18|Allow required inputs to specify default data in DDLs|17615|
|2012/11/12|When disconnecting set the connection to nil|17384|
|2012/11/08|Define a specific buildroot to support RHEL5 systems correctly|17516|
|2012/11/08|Use the correct rpmbuild commands on systems with rpmbuild-md5|17515|
|2012/10/22|Correctly show help for data plugins without any input queries|17137|
|2012/10/22|Allow the rpcutil#get_data action to work with data queries that takes no input|17138|
|2012/10/03|Improve text output when providing custom formats for aggregations|16735|
|2012/10/03|Correctly process supplied formats when displaying aggregate results|16415|
|2012/10/03|Prevent one failing aggregate function from impacting others|16411|
|2012/10/03|When validation fails indicate which input key has the problem|16617|
|2012/09/26|Data queries can be written without any input queries meaning they take no input|16424|
|2012/09/26|Use correct timeout for agent requests when using direct addressing|16569|
|2012/09/26|Allow BigNum data to be used in data plugin replies|16503|
|2012/09/26|Support non string data in the summary aggregate function|16410|

## Version 2.2.x

|Date|Description|Ticket|
|----|-----------|------|
|*2013/05/21*|*Release 2.2.4*|20592|
|2013/05/10|Correctly detect version differences in semver version where the path level is greater 10|20661|
|2013/05/07|Support the latest version of the JSON gem|20594|
|2013/04/29|Improve config defaults on windows machines|20388|
|2013/03/13|Set correct reply-to headers in the RabbitMQ connector|17034|
|2013/03/12|Explicitly include StringIO|19367|
|*2013/02/14*|*Release 2.2.3*|19265|
|2013/02/14|Update vendored JSON gem for CVE-2013-0269|19265|
|2013/02/13|Restore the ability to set a discovery timeout on a RPC client|19238|
|2013/02/12|Replace underscores in plugin names with dashes to keep Debian happy|19200|
|2013/02/12|Fix package building on certain Debian systems|19141|
|2013/02/12|Deprecate the stomp connector|19146|
|2013/02/07|Read the client config before trying to use any configuration options|19105|
|2013/01/22|Set *=* dependencies on the various packages that form a plugin rather than *>=*|18758|
|*2013/01/17*|*Release 2.2.2*|18258|
|2013/01/03|Add the package iteration number as a dependency for the common packages|18273|
|2012/12/24|Restore the :any validator|18265|
|2012/12/19|Do not fail when packaging non-agent packages using custom paths|17281|
|2012/12/19|Require Ruby > 1.8 in the RPM specs for Ruby 1.9|17149|
|2012/11/08|Define a specific buildroot to support RHEL5 systems correctly|17516|
|2012/11/08|Use the correct rpmbuild commands on systems with rpmbuild-md5|17515|
|2012/10/22|Correctly show help for data plugins without any input queries|17137|
|2012/10/22|Allow the rpcutil#get_data action to work with data queries that takes no input|17138|
|*2012/10/17*|*Release 2.2.1*|16965|
|2012/10/03|Improve text output when providing custom formats for aggregations|16735|
|2012/10/03|Correctly process supplied formats when displaying aggregate results|16415|
|2012/10/03|Prevent one failing aggregate function from impacting others|16411|
|2012/10/03|When validation fails indicate which input key has the problem|16617|
|2012/09/26|Data queries can be written without any input queries meaning they take no input|16424|
|2012/09/26|Use correct timeout for agent requests when using direct addressing|16569|
|2012/09/26|Allow BigNum data to be used in data plugin replies|16503|
|2012/09/26|Support non string data in the summary aggregate function|16410|
|2012/09/14|Package discovery plugins that was left out for debian|16413|
|*2012/09/13*|*Release 2.2.0*|16323|

## Version 2.1.x

|Date|Description|Ticket|
|----|-----------|------|
|2012/09/10|Update the vendored systemu gem|16289|
|2012/09/06|Improve error reporting for empty certificate files|15924|
|2012/09/05|Restore the verbose behavior while building packages|16216|
|2012/09/04|Add a fetch method that mimic Hash#fetch to RPC Results and Requests|16222|
|2012/09/04|Include the required mcollective version in packages that include the requirement|16173|
|2012/08/29|Add a RabbitMQ specific connector plugin|16168|
|2012/08/22|DDL files can now specify which is the minimal version of mcollective they require|15850|
|2012/08/22|Fix a bug when specifying a custom target directory for packages|15956|
|2012/08/22|When producing plugin packages keep the source deb and rpm|15917|
|2012/08/09|Improve error handling in the plugin application|15848|
|2012/08/08|Add the ability to store general usage information in the DDL|15633|
|2012/08/02|Restore the formatting of the progress bar that was broken in 14255|15805|
|2012/08/01|Display an error when no aggregate results could be computed|15793|
|2012/08/01|Create a plugin system for validators|5078|
|2012/07/19|Create a thread safe caching layer and use it to optimize loading of DDL files|15582|
|2012/07/19|Correctly calculate discovery timeout in all cases and simplify logic around this|15602|
|2012/07/17|Update the *name* field in the rpcutil DDL for consistency|15558
|2012/07/17|Validate requests against the DDL in the agents prior to authorization or calling actions|15557|
|2012/07/17|Refactor the single big DDL class into a class per type of plugin|15109|
|2012/07/16|Default to the configured default discovery method in the RPC client when nothing is supplied|15506|
|2012/07/16|Improve error handling in generate application|15473|
|*2012/07/12*|*Release 2.1.1*|15379|
|2012/07/11|Add a --display option to RPC clients that overrides the DDL display mode|15273|
|2012/07/10|Do not add a metadata to agents created with the generator as they are now deprecated|15445|
|2012/07/03|Correctly parse numeric and boolean data on the CLI in the rpc application|15344|
|2012/07/03|Fix a bug related to parsing regular expressions in compound statements|15323|
|2012/07/02|Update vim snippets in ext for new DDL features|15273|
|2012/06/29|Create a common package for agent packages containing the DDL for servers and clients|15268|
|2012/06/28|Improve parsing of compound filters where the first argument is a class|15271|
|2012/06/28|Add the ability to declare automatic result summarization in the DDL files for agents|15031|
|2012/06/26|Suppress subscribing to reply queues when no reply is expected|15226|
|2012/06/25|Batched RPC requests will now all have the same requestid|15195|
|2012/06/25|Record the request id on M::Client and in the RPC client stats|15194|
|2012/06/24|Use UUIDs for the request id rather than our own weak implementation|15191|
|2012/06/18|The DDL can now define defaults for outputs and the RPC replies are pre-populated|15087|
|2012/06/18|Remove unused agent help code|15084|
|2012/06/18|Remove unused code from the *discovery* agent related to inventory and facts|15083|
|2012/06/18|Nodes will now refuse to load RPC agents without DDL files|15082|
|2012/06/18|The Plugin Name and Type is now available to DDL objects|15076|
|2012/06/15|Add a get_data action to the rpcutil agent that can retrieve data from data plugins|15057|
|2012/06/14|Allow the random selection of nodes to be deterministic|14960|
|2012/06/12|Remove the Client#discovered_req method and add warnings to the documentation about its use|14777|
|2012/06/11|Add a discovery source capable of doing introspection on running agents|14945|
|2012/06/11|Only do identity filter optimisations for the *mc* discovery source|14942|
|*2012/06/08*|*Release 2.1.0*|14846|
|2012/06/07|Force discovery state to be reset when changing collectives in the RPC client|14874|
|2012/06/07|Create code generators for agents and data plugins|14717|
|2012/06/07|Fix the _No response from_ report to be correctly formatted|14868|
|2012/06/07|Sub collectives and direct addressing mode now works correctly|14668|
|2012/06/07|The discovery method is now pluggable, included is one supporting flat files|14255|
|2012/05/28|Add an application to assist shell completion systems with bash and zsh completion plugins|14196|
|2012/05/22|Improve error messages from the packager when a DDL file cannot be found|14595|
|2012/05/17|Add a dependency on stomp to the rubygem|14300|
|2012/05/17|Adjust the ActiveMQ and Stomp connect_timeout to allow IPv4 fall back to happen in dual homed hosts|14496|
|2012/05/16|Add a plugable data source usable in discovery and other plugins|14254|
|2012/05/04|Improve version dependencies and upgrade experience of debian packages|14277|
|2012/05/03|Add the ability for the DDL to load DDL files from any plugin type|14293|
|2012/05/03|Rename the MCollective::RPC::DDL to MCollective::DDL to match its larger role in all plugins|14254|

## Version 2.0.x

|Date|Description|Ticket|
|----|-----------|------|
|*2013/02/14*|*Release 2.0.1*|19265|
|2013/02/14|Update vendored JSON gem for CVE-2013-0269|19265|
|2012/05/04|Improve version dependencies and upgrade experience of debian packages|14277|
|*2012/04/30*|*Release 2.0.0*|13900|

## Version 1.3.x

|Date|Description|Ticket|
|----|-----------|------|
|2012/04/30|Compound filters when set from the RPC client were not working|14239|
|2012/04/25|Various improvements to the RPM spec file wrt licencing, dependencies etc|9451|
|2012/04/25|Support using rpmbuild-md5 to create RPMs and support Fedora|14159|
|2012/04/25|Improve LSB compliance in the Red Hat and Debian RC scripts|14151|
|2012/04/19|Fix reference to _topicnamesep_ and remove _topicprefix_ from examples|13873|
|2012/04/19|Remove dependency on FPM for building RPM and Deb packages|13573|
|2012/04/18|Improve default output format from the mco script|14056|
|2012/04/17|Remove unintended requirement that only newest stomp gems be used|13978|
|2012/04/12|New init script for Debian that uses LSB functions to start and stop the daemon|13043|
|2012/04/12|Use sed -i in the Rakefile to improve compatibility with OS X|13324|
|2012/04/11|Fix compatibility with Ruby 1.9.1 by specifically loading rbconfig early on|13872|
|*2012/04/05*|*Release 1.3.3*|13599|
|2012/04/04|Use the MCollective::SSL utility class for crypto functions in the SSL security plugin|13615|
|2012/04/02|Support reading public keys from SSL Certificates as well as keys|13534|
|2012/04/02|Move the help template to the common package for both Debian and RedHat|13434|
|2012/03/30|Support Stomp 1.2.2 CA verified connection to ActiveMQ|10596|
|2012/03/27|_mco help rpc_ now shows the help for the rpc application|13350|
|2012/03/22|Add a mco command that creates native OS packaging for plugins|12597|
|2012/03/21|Default to console based logging at warning level for clients|13285|
|2012/03/20|Work around SSL_read errors when using SSL or AES plugins and Stomp+SSL in Ruby < 1.9.3|13207|
|2012/03/16|Improve logging for SSL connections when using Stomp Gem newer than 1.2.0|13165|
|2012/03/14|Simplify handling of signals like TERM and INT and remove pid file on exit|13105|
|2012/03/13|Create a conventional place to store implemented_by scripts|13064|
|2012/03/09|Handle exceptions added to the Stomp 1.1 compliant versions of the Stomp gem|13020|
|2012/03/09|Specifically enable reliable communications while using the pool style syntax|13040|
|2012/03/06|Initial support for the Windows Platform|12555|
|2012/03/05|Application plugins can now disable any of 3 sections of the standard CLI argument parsers|12859|
|2012/03/05|Fix base 64 encoding and decoding of message payloads that would previous raise unexpected exceptions|12950|
|2012/03/02|Treat :hosts and :nodes as equivalents when supplying discovery data, be more strict about flags discover will accept|12852|
|2012/03/02|Allow exit() to be used everywhere in application plugins, not just in the main method|12927|
|2012/03/02|Allow batch mode to be enabled and disabled on demand during the life of a client|12854|
|2012/02/29|Show the progress bar before sending any requests to give users feedback as soon as possible rather than after first result only|12865|
|2012/02/23|Do not log exceptions in the RPC application when a non existing action is called with request parameters|12719|
|2012/02/17|Log miscellaneous Stomp errors at error level rather than debug|12705|
|2012/02/17|Improve subscription tracking by using the subID feature of the Stomp gem and handle duplicate exceptions|12703|
|2012/02/15|Improve error handling in the inventory application for non responsive nodes|12638|
|2012/02/14|Comply to Red Hat guideline by not setting mcollective to start by default after RPM install|9453|
|2012/02/14|Allow building the client libraries as a gem|9383|
|2012/02/13|On Red Hat like systems read /etc/sysconfig/mcollective in the init script to allow modification of the environment|7441|
|2012/02/13|Make the handling of symlinks to the mco script more robust to handle directories with mc- in their name|6275|
|2012/02/01|systemu and therefore MC::Shell can sometimes return nil exit code, the run() method now handles this better by returning -1 exit status|12082|
|2012/01/27|Improve handling of discovery data on STDIN to avoid failures when run without a TTY and without supplying discovery data|12084|
|2012/01/25|Allow the syslog facility to be configured|12109|
|2012/01/13|Add a RPC agent validator to ensure input is one of list of known good values|11935|
|2012/01/09|The printrpc helper did not correctly display empty strings in received output|11012|
|2012/01/09|Add a halt method to the Application framework and standardize exit codes|11280|
|2011/11/21|Remove unintended dependency on _pp_ in the ActiveMQ plugin|10992|
|2011/11/17|Allow reply to destinations to be supplied on the command line or API|9847|
|*2011/11/17*|*Release 1.3.2*|*10830*|
|2011/11/16|Improve error reporting for code errors in application plugins|10883|
|2011/11/15|The limit method is now configurable on each RPC client as well as the config file|7772|
|2011/11/15|Add a --graph option to the ping application that shows response distribution|10864|
|2011/11/14|An ActiveMQ specific connector was added that supports direct connections|7899|
|2011/11/11|SimpleRPC clients now support native batching with --batch|5939|
|2011/11/11|The client now unsubscribes from topics when it's idle minimising the risk of receiving misdirected messages|10670|
|2011/11/09|Security plugins now ignore miss directed messages early thus using fewer resources|10671|
|2011/10/28|Support ruby-1.9.2-p290 and ruby-1.9.3-rc1|10352|
|2011/10/27|callerid, certificate names, and identity names can now only have \w . and - in them|10327|
|2011/10/25|When discovery information is provided always accept it without requiring reset first|10265|
|2011/10/24|Add :number, :integer and :float to the DDL and rpc application|9902|
|2011/10/22|Speed up discovery when limit targets are set|10133|
|2011/10/22|Do not attempt to validate TTL and Message Times on replies in the SSL plugin|10226|
|2011/10/03|Allow the RPC client to raise an exception rather than exit on failure|9360|
|2011/10/03|Allow the TTL of requests to be set in the config file and the SimpleRPC API|9399|
|2011/09/26|Cryptographically secure the TTL and Message Time of requests when using AES and SSL plugins|9400|
|2011/09/20|Update default shipped configurations to provide a better out of the box experience|9452|
|2011/09/20|Remove deprecated mc- scripts|9402|
|2011/09/20|Keep track of messages that has expired and expose the stat in rpcutil and inventory application|9456|
|*2011/09/16*|*Release 1.3.1*|*9133*|
|2011/09/9|Use direct messaging where possible for identity filters and make the rpc application direct aware|8466|
|2011/08/29|Enforce a 60 second TTL on all messages by default|8325|
|2011/08/29|Change the default classes.txt file to be in line with Puppet defaults|9133|
|2011/08/06|Add reload-agents and reload-loglevel commands to the redhat RC script|7730|
|2011/08/06|Avoid reloading the authorization class over and over from disk on each request|8703|
|2011/08/06|Add a boolean validator to SimpleRPC agents|8799|
|2011/08/06|Justify text results better when using printrpc|8807|
|2011/07/22|Add --version to the mco utility|7822|
|2011/07/22|Add missing meta data to the discovery agent|8497|
|2011/07/18|Raise an error if invalid format fact filters are supplied|8419|
|2011/07/14|Add a rich discovery query language|8181|
|2011/07/08|Do not set RUBYLIB in the RC scripts, the OS should do the right thing|8063|
|2011/07/07|Add a -j argument to all SimpleRPC clients that causes printrpc to produce JSON data|8280|
|2011/06/30|Add the ability to do point to point comms for requests affecting small numbers of hosts|7988|
|2011/06/21|Add support for Stomp Gem version 1.1.9 callback based logging|7960|
|2011/06/21|On the server side log missing DDL files at debug and not warning level|7961|
|2011/06/16|Add the ability for nodes to subscribe to per-node queues, off by default|7225|
|2011/06/12|Remove assumptions about middleware structure from the core and move it to the connector plugins|7619|
|*2011/06/08*|*Release 1.3.0*|7796|
|2011/06/07|Exceptions raised during option parsing were not handled and resulted in stack traces|7796|
|2011/06/06|Remove the sshkey, it's being moved to the plugin repository|7794|
|2011/06/02|Correct parsing of MCOLLECTIVE_EXTRA_OPTS in cases where no config related settings were set|7755|
|2011/05/31|Disconnect from the middleware when an application calls exit|7712|
|2011/05/29|Validations failure in RPC agents will now raise the correct exceptions as documented|7711|
|2011/05/25|Make the target collective for registration messages configurable|7650|
|2011/05/24|Rename the connector plugins send method to publish to avoid issues ruby Object#send|7623|
|2011/05/23|Log a warning when the CF file parsing fails rather than raise a whole ruby exception|7627|
|2011/05/23|Allow applications to use the exit method as would normally be expected|7626|
|2011/05/22|Refactor subscribe and unsubscribe so that middleware structure is entirely contained in the connectors|7620|
|2011/05/21|Add the ability for agents to programatically declare if they should work on a node|7583|
|2011/05/20|Improve error reporting in the single application framework|7574|
|2011/05/16|Allow _._ in fact names|7532|
|2011/05/16|Fix compatability issues with RH4 init system|7448|
|2011/05/15|Handle failures from remote nodes better in the inventory app|7524|
|2011/05/06|Revert unintended changes to the Debian rc script|7420|
|2011/05/06|Remove the _test_ agent that was accidentally checked in|7425|

## Version 1.2.x

|Date|Description|Ticket|
|----|-----------|------|
|*2011/06/30*|*Release 1.2.1*|8117|
|2011/06/02|Correct parsing of MCOLLECTIVE_EXTRA_OPTS in cases where no config related settings were set|7755|
|2011/05/23|Allow applications to use the exit method as would normally be expected|7626|
|2011/05/16|Allow _._ in fact names|7532|
|2011/05/16|Fix compatability issues with RH4 init system|7448|
|2011/05/15|Handle failures from remote nodes better in the inventory app|7524|
|2011/05/06|Revert unintended changes to the Debian rc script|7420|
|2011/05/06|Remove the _test_ agent that was accidentally checked in|7425|
|*2011/05/04*|*Release 1.2.0*|7227|

## Version 1.1.x

|Date|Description|Ticket|
|----|-----------|------|
|2011/05/03|Improve Red Hat RC script by using distro builtin functions|7340|
|2011/05/01|Support setting a priority on Stomp messages|7246|
|2011/04/30|Handle broken and incomplete DDLs better and improve the format of DDL output|7191|
|2011/04/23|Encode the target agent and collective in requests|7223|
|2011/04/20|Make the SSL Cipher used a config option|7191|
|2011/04/20|Add a clear method to the PluginManager that deletes all plugins, improve test isolation|7176|
|2011/04/19|Abstract the creation of request and reply hashes to simplify connector plugin development|5701|
|2011/04/15|Improve the shellsafe validator and add a Util method to do shell escaping|7066|
|2011/04/14|Update Rakefile to have a mail_patches task|6874|
|2011/04/13|Update vendored systemu library for Ruby 1.9.2 compatability|7067|
|2011/04/12|Fix failing tests on Ruby 1.9.2|7067|
|2011/04/11|Update the DDL documentation to reflect the _mco help_ command|7042|
|2011/04/11|Document the use filters on the CLI|5917|
|2011/04/11|Improve handling of unknown facts in Util#has_fact? to avoid exceptions about nil#clone|6956|
|2011/04/11|Correctly set timeout on the discovery agent to 5 seconds as default|7045|
|2011/04/11|Let rpcutil#agent_inventory supply _unknown_ for missing values in agent meta data|7044|
|*2011/04/07*|*Release 1.1.4*|6952|
|2011/03/28|Correct loading of vendored JSON gem|6877|
|2011/03/28|Show collective and sub collective info in the inventory application|6872|
|2011/03/23|Disconnect from the middleware when mcollectived disconnects|6821|
|2011/03/21|Update rpcutil ddl file to be less strict about valid fact names|6764|
|2011/03/22|Support reading configuration from configfir/plugin.d for plugins|6623|
|2011/03/21|Update default configuration files for subcollectives|6741|
|2011/03/16|Add the ability to implement actions using external scripts|6705|
|2011/03/15|Port mc-controller to the Application framework and deprecate the exit command|6637|
|2011/03/13|Only cache registration and discovery agents, handle the rest as new instances|6692|
|2011/03/08|PluginManager can now create new instances on demand for a plugin type|6622|
|*2011/03/07*|*Release 1.1.3*|6609|
|2011/03/04|Rename /usr/sbin/mc to /usr/bin/mco|6578|
|2011/03/01|Wrap rpcclient in applications ensuring that options is always set|6308|
|2011/02/28|Make communicating with the middleware more robust by including send calls in timeouts|6505|
|2011/02/28|Create a wrapper to safely run shell commands avoiding zombies|6392|
|2011/02/19|Introduce Subcollectives for network partitioning|5967|
|2011/02/19|Improve error handling when parsing arguments in the rpc application|6388|
|2011/02/19|Fix error logging when file_logger creation fails|6387|
|2011/02/17|Correctly parse MCOLLECTIVE_EXTRA_OPTS in the new unified binary framework|6354|
|2011/02/15|Allow the signing key and Debian distribution to be customized|6321|
|2011/02/14|Remove inadvertently included package.ddl|6313|
|2011/02/14|Handle missing libdirs without crashing|6306|
|*2011/02/14*|*Release 1.1.2*|6303|
|2011/02/13|Surpress replies to SimpleRPC clients who did not request results|6305|
|2011/02/11|Fix Debian packaging error due to the same file in multiple packages|6276|
|2011/02/11|The application framework will now disconnect from the middleware for consistancy|6292|
|2011/02/11|Returning _nil_ from a registration plugin will skip registration|6289|
|2011/02/11|Set loglevel to warn by default if not specified in the config file|6287|
|2011/02/10|Fix backward compatability with empty fact strings|6278|
|*2011/02/07*|*Release 1.1.1*|6080|
|2011/02/02|Load the DDL from disk once per printrpc call and not for every result|5958|
|2011/02/02|Include full Apache 2 license text|6113|
|2011/01/31|Create a new single executable application framework|5897|
|2011/01/30|Fix backward compatibility with old foo=/bar/ style fact searches|5985|
|2011/01/30|Documentation update to reflect correct default identity behavior|6073|
|2011/01/29|Let the YAML file force fact reloads when the files update|6057|
|2011/01/29|Add the ability for fact plugins to force fact invalidation|6057|
|2011/01/29|Document an approach to disable type validation in the DDL|6066|
|2011/01/19|Add basic filters to the mc-ping command|5933|
|2011/01/19|Add a ping action to the rpcutil agent|5937|
|2011/01/17|Allow MC::RPC#printrpc to print single results|5918|
|2011/01/16|Provide SimpleRPC style results when accessing the MC::Client results directly|5912|
|2011/01/11|Add an option to Base64 encode the STOMP payload|5815|
|2011/01/11|Fix a bug with forcing all facts to be strings|5832|
|2011/01/08|When using reload_agents or USR1 signal no agents would be reloaded|5808|
|2011/01/04|Use the LSB based init script on SUSE|5762|
|2011/01/04|Remove the use of a Singleton in the logging class|5749|
|2011/01/02|Add AES+RSA security plugin|5696|
|2010/12/31|Security plugins now have access to the callerid of the message they are replying to|5745|
|2010/12/30|Allow - in fact names|5727|
|2010/12/29|Treat machines that fail security validation like ones that did not respond|5700|
|*2010/12/29*|*Release 1.1.0*|5695|
|2010/12/28|Remove trailing whitespace from all source files|5702|
|2010/12/28|Adjust the logfile audit format to include local time and all on one line|5694|
|2010/12/26|Improve the SimpleRPC fact_filter helper to support new fact operators|5678|
|2010/12/25|Increase the rpcutil timeout to allow for slow facts|5679|
|2010/12/25|Allow for network and fact source latency when calculating client timeout|5676|
|2010/12/25|Remove MCOLLECTIVE_TIMEOUT and MCOLLECTIVE_DTIMEOUT environment vars in favour of MCOLLECTIVE_EXTRA_OPTS|5675|
|2010/12/25|Refactor the creation of the options hash so other tools don't need to know the internal formats|5672|
|2010/12/21|The fact plugin format has been changed and simplified, the base now provides caching and thread safety|5083|
|2010/12/20|Add parameters <=, >=, <, >, !=, == and =~ to fact selection|5084|
|2010/12/14|Add experimental sshkey security plugin|5085|
|2010/12/13|Log a startup message showing version and log level|5538|
|2010/12/13|Add a console logger|5537|
|2010/12/13|Logging is now plugable and a syslog plugin was provided|5082|
|2010/12/13|Allow libdir to be an array of directories for agents and ddl files|5253|
|2010/12/13|The progress bar will now intelligently figure out the terminal dimentions|5524|

## Version 1.0.x

|Date|Description|Ticket|
|----|-----------|------|
|*2011/02/16*|*Release 1.0.1*|6342|
|2011/02/02|Include full Apache 2 license text|6113|
|2011/01/29|The YAML fact plugin kept deleted facts in memory|6056|
|2011/01/04|Use the LSB based init script on SUSE|5762|
|2010/12/30|Allow - in fact names|5727|
|2010/12/29|Treat machines that fail security validation like ones that did not respond|5700|
|2010/12/25|Allow for network and fact source latency when calculating client timeout|5676|
|2010/12/25|Increase the rpcutil timeout to allow for slow facts|5679|
|*2010/12/13*|*Release 1.0.0*|5453|

## Version 0.4.x

|Date|Description|Ticket|
|----|-----------|------|
|2010/12/04|Remove the LSB requirements for RedHat systems|5451|
|2010/11/23|Make the YAML fact source thread safe and force all facts to strings|5377|
|2010/11/23|Add get_config_item to rpcutil to retrieve a running config value from a server|5376|
|2010/11/20|Convert mc-facts into a SimpleRPC client|5371|
|2010/11/18|Added GPG signing to Rake packaging tasks (SIGNED=1)|5355|
|2010/11/17|Improve error messages from clients in the case of failure|5329|
|2010/11/17|Add helpers to disconnect from the middleware and update all bundled clients|5328|
|2010/11/16|Correct LSB provides and requires in default init script|5222|
|2010/11/16|Input validation on rpcutil has been improved to match all valid facts|5320|
|2010/11/16|Add the ability to limit the results to a subset of hosts|5306|
|2010/11/15|Add fire and forget mode to SimpleRPC custom_request|5305|
|2010/11/09|General connection settings to the Stomp connector was ignored|5245|
|*2010/10/18*|*Release version 0.4.10*| |
|2010/10/18|Document exit command to mc-controller|152|
|2010/10/13|Log messages that don't pass the filters at debug level|149|
|2010/10/03|Preserve options in cases where RPC::Client instances exist in the same program|148|
|2010/09/30|Add the ability to set different types of callerid in the PSK plugin|145|
|2010/09/30|Improve Ruby 1.9.x compatibility|142|
|2010/09/29|Improve error handling in registration to avoid high CPU usage loops|143|
|*2010/09/21*|*Release version 0.4.9*| |
|2010/09/20|Improve Debian packaging task|140|
|2010/09/20|Add :boolean type support to the DDL|138|
|2010/09/19|Refactor MCollective::RPC to add less unneeded stuff to Object|137|
|2010/09/18|Prevent duplicate config loading with multiple clients active|136|
|2010/09/18|Rotate the log file by default, keeping 5 x 2MB files|135|
|2010/09/18|Write a overview document detailing security of the collective|131|
|2010/09/18|Add MCollective.version, set it during packaging and include it in the rpcutil agent|134|
|2010/09/13|mc-inventory now use SimpleRPC and the rpcutil agent and display server stats|133|
|2010/09/13|Make the path to the rpc-help.erb configurable and set sane default|130|
|2010/09/13|Make the configfile used available in the Config class and add to rpcutil|132|
|2010/09/12|Rework internal statistics and add a rpcutil agent|129|
|2010/09/12|Fix internal memory structures related to agent meta data|128|
|2010/08/24|Update the OpenBSD port for changes in 0.4.8 tarball|125|
|2010/08/23|Fix indention/block error in M:R:Stats|124|
|2010/08/23|Fix permissions in the RPM for files in /etc|123|
|2010/08/23|Fix language in two error messages|122|
|*2010/08/20*|*Release version 0.4.8*| |
|2010/08/19|Fix missing help template in debian packages|90|
|2010/08/18|Clean up some hardlink warnings in the Rakefile|117|
|2010/08/18|Include the website in the main repo and add a simple Rake task|118|
|2010/08/17|Handle exceptions for missing plugins better|115|
|2010/08/17|Add support for ~/.mcollective as a config file|114|
|2010/08/07|SSL security plugin can use either YAML or Marshal|94|
|2010/08/06|Multiple YAML files can now be used as fact source|112|
|2010/08/06|Allow log level to be adjusted at run time with USR2|113|
|2010/07/31|Add basic report scripting support to mc-inventory|111|
|2010/07/06|Removed 'rpm' from the default rake task|109|
|2010/07/06|Add redhat-lsb to the server RPM dependencies|108|
|*2010/06/29*|*Release version 0.4.7*| |
|2010/06/27|Change default factsource to Yaml|106|
|2010/06/27|Added VIM snippets to create DDLs and Agents|102|
|2010/06/26|DDL based help now works better with Symbols in in/output|105|
|2010/06/23|Whitespace at the end of config lines are now stripped|100|
|2010/06/22|printrpc will now inject some colors into results|99|
|2010/06/22|Recover from syntax and other errors in agents|98|
|2010/06/17|The agent a MC::RPC::Client is working on is now available|97|
|2010/06/17|Integrate the DDL with data display helpers like printrpc|92|
|2010/06/15|Avoid duplicate topic subscribes in complex clients|95|
|2010/06/15|Catch some unhandled exceptions in RPC Agents|96|
|2010/06/15|Fix missing help template file from RPM|90|
|*2010/06/14*|*Release version 0.4.6* | |
|2010/06/12|Qualify the Process class to avoid clashes in the discovery agent|88|
|2010/06/12|Add mc-inventory which shows agents, classes and facts for a node|87|
|2010/06/11|mc-facts now supports standard filters|86|
|2010/06/11|Add connection pool retry options and ssl for connection|85|
|2010/06/11|Add support for specifying multiple stomp hosts for failover|84|
|2010/06/10|Tighten up handling of filters to avoid nil's getting into them|83|
|2010/06/09|Sort the mc-facts output to be more readable|82|
|2010/06/08|Fix deprecation warnings in newer Stomp gems|81|
|*2010/06/03*|*Release version 0.4.5* | |
|2010/06/01|Improve the main discovery agent by adding facts and classes to its inventory action|79|
|2010/05/30|Add various helpers to get reports as text instead of printing them|43|
|2010/05/30|Add a custom_request method to call SimpleRPC agents with your own discovery|75|
|2010/05/30|Refactor RPC::Client to be more generic and easier to maintain|75|
|2010/05/29|Fix a small scoping issue in Security::Base|76|
|2010/05/25|Add option --no-progress to disable progress bar for SimpleRPC|74|
|2010/05/23|Add some missing dependencies to the RPMs|72 |
|2010/05/22|Add an option _:process_results_ to the client|71|
|2010/05/13|Fix help output that still shows old branding|70|
|2010/04/27|The supplied generic stompclient now accepts STOMP_PORT in the environment|68 |
|2010/04/26|Add a SimpleRPC Client helper to reset filters|64 |
|2010/04/26|Listen for signal USR1 and reload all agents from disk|65 |
|2010/04/12|Add SimpleRPC Authorization support|63|
|*2010/04/03*|*Release version 0.4.4* | |
|2010/03/27|Make it easier to construct SimpleRPC requests to use with the standard client library|60 |
|2010/03/27|Manipulating the filters via the helper methods will force rediscovery|59 |
|2010/03/23|Prevent Activesupport when brought in by Facter from breaking our logs|57 |
|2010/03/23|Clean up logging for messages not targeted at us|56 |
|2010/03/19|Add exception handling to the registration base class|55 |
|2010/03/03|Use /usr/bin/env ruby instead of hardcoded paths|54|
|2010/02/17|Improve mc-controller and document it|46|
|2010/02/08|Remove some close coupling with Stomp to easy creating of other connectors|49|
|2010/02/01|Made the discovery agent timeout configurable using plugin.discovery.timeout|48|
|2010/01/25|mc-controller now correctly loads/reloads agents.|45|
|2010/01/25|Building packages has been improved to ensure rdocs are always included|44 |
|*2010/01/24*|*Release version 0.4.3* | |
|2010/01/23|Handle ctrl-c during discovery without showing exceptions to users|34 |
|2010/01/21|Force all facts in the YAML fact source to be strings|41 |
|2010/01/19|Add auditing to SimpleRPC clients and Agents | |
|2010/01/18|The SRPM we provide will now build outside of the Rake environment|40|
|2010/01/18|Add a _fail!_ method to RPC::Agent|37|
|2010/01/18|mc-rpc can now be used without supplying arguments|38 |
|2010/01/18|Don't raise an error if no user/pass is given to the stomp connector, try unauthenticated mode|35|
|2010/01/17|Improve error message when Regex validation failed on SimpleRPC input|36|
|*2010/01/13*|*Release version 0.4.2* | |
|2010/01/13|New packaging for Debian provided by Riccardo Setti|29|
|2010/01/07|Improved LSB compliance of the init script - thanks Riccardo Setti|32|
|2010/01/07|Multiple calls to SimpleRPC client would reset discovered hosts|31|
|2010/01/04|Timeouts can now be changed with MCOLLECTIVE_TIMEOUT and MCOLLECTIVE_DTIMEOUT environment vars|25|
|2010/01/04|Specify class and fact filters easier with the new -W or --with option|27 |
|2010/01/04|Added COPYING file to RPMs and tarball|28|
|2010/01/04|Make shorter filter options -C, -I, -A and -F|26|
|*2010/01/02*|*Release version 0.4.1* | |
|2010/01/02|Added hooks to plug into the processing of requests, also enabled setting meta data and timeouts|14|
|2010/01/02|Created readers for @config and @logger in the SimpleRPC agent|23|
|2009/12/30|Don't send out any requests if no nodes were discovered|17|
|2009/12/30|Added :discovered and :discovered_nodes to client stats|20|
|2009/12/30|Add a empty_filter? helper to the RPC mixin|18|
|2009/12/30|Fix formatting bug with progress bar|21|
|2009/12/29|Simplify mc-rpc command line|16|
|2009/12/29|Fix layout issue when printing hosts that did not respond|15|
|*2009/12/29*|*Release version 0.4.0* | |
|2009/12/28|Add support for other configuration management systems in the --with-class filters|13|
|2009/12/28|Add a <em>Util.empty_filter?</em> to test for an empty filter| |
|2009/12/27|Create a new client framework - SimpleRPC|6|
|2009/12/27|Add support for multiple filters of the same type|3|

## Version 0.3.x

|Date|Description|Ticket|
|----|-----------|------|
|*2009/12/17*|*Release version 0.3.0* | |
|2009/12/16|Improvements for newer versions of Ruby where TERM signal was not handled|7|
|2009/12/07|MCollective::Util is now a module and plugins can drop in util classes in the plugin dir| |
|2009/12/07|The Rakefile now works with rake provided on Debian 4 systems|2|
|2009/12/07|Improvements in the RC script for Debian and older Ubuntu systems|5|

## Version 0.2.x

|Date|Description|Ticket|
|2009/12/01|Release version 0.2.0| |
