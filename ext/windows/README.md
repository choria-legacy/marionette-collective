These files support installing and using MCollective on MS Windows.

Here are a few instructions for people who wish to do early adopter testing. At some point we hope to have this packaged into an MSI installer, but your early feedback will help. This guide doesn't include installing a message broker and the process may or may not work as described. Some additional troubleshooting/experimentation will probably be necessary.

Assuming you are installing MCollective into `C:\marionette-collective`:

 * Install Ruby 1.9.3 from <http://rubyinstaller.org/>
      * check the boxes for "Add Ruby executables to your PATH" and "Associate .rb and .rbw files with the Ruby installation"
 * Run the following commands to install the required gems:
      * `gem install --no-rdoc --no-ri stomp win32-service sys-admin windows-api`
      * `gem install --no-rdoc --no-ri win32-dir -v 0.3.7`
      * `gem install --no-rdoc --no-ri win32-process -v 0.5.5`
 * Extract the zip file or clone the git repository into `C:\marionette-collective`
 * Copy the files from `C:\marionette-collective\ext\windows\` into `C:\marionette-collective\bin`
 * Install any plugins and their dependencies into `C:\marionette-collective\plugins`
   specifically for the package and service agents. You can install Puppet via gems.
 * Edit the configuration files in `C:\marionette-collective\etc\`:
      * Rename `server.cfg.dist` to `server.cfg` and change the following settings:
         * `libdir = C:\marionette-collective\plugins`
         * `logfile = C:\marionette-collective\mcollective.log`
         * `plugin.yaml = C:\marionette-collective\etc\facts.yaml`
      * Rename `client.cfg.dist` to `client.cfg` and rename `facts.yaml.dist` to `facts.yaml`
 * Register and start the service
      * Enter the `C:\marionette-collective\bin\` directory and run `register_service.bat`
      * Right click on "My Computer," select "Manage"
      * Under "Services and Applications," expand "Services"
      * Find "The Marionette Collective" and start the service

If it does not run:

 * Look in the log files. Edit `server.cfg` to set `loglevel` to `debug`. 
 * If the log files are empty, look at the command the service wrapper runs and run it by hand. This will show you any early exceptions preventing it from running. It wont succesfully start, but you should see why it does not get far enough to start writing logs.
 
