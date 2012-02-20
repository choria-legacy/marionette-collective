These files support installing and using mcollective on MS Windows.

Here are a few instructions for people who wish to do early adopter
testing, before 2.0 is out we hope to have this packaged into a msi
installer but your early feedback will help.

Assuming you are installing mcollective into C:\marionette-collective:

 * Install Ruby from http://rubyinstaller.org/, use 1.8.7
 * Install the following gems: stomp, win32-process, win32-service,
   sys-admin, windows-api
 * extract the zip file or clone the git repo into C:\marionette-collective
 * copy the files from C:\marionette-collective\ext\windows\*.* into
   C:\marionette-collective\bin
 * Install any plugins and their dependencies into C:\marionette-collective\plugins
   specifically for the package and service agents you can install Puppet via gems
 * Edit the configuration files setting:
   * libdir = c:\marionette-collective\plugins
   * logfile = c:\marionette-collective\mcollective.log
   * plugin.yaml = c:\marionette-collective\etc\facts.ysml
   * daemonize = 1
 * change directories to c:\marionette-collective\bin and run register_service.bat

At this point you would have your service registered into the windows service
manager but set to manual start.  If you start it there it should run ok.

If it does not run:

 * Look in the log files, set it to debug level
 * If the log files are empty look at the command the service wrapper runs
   and run it by hand.  This will show you any early exception preventing it
   from running.  It wont succesfully start but you should see why it does
   not get far enough to start writing logs.

