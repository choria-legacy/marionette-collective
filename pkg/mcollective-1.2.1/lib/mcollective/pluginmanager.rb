module MCollective
    # A simple plugin manager, it stores one plugin each of a specific type
    # the idea is that we can only have one security provider, one connector etc.
    module PluginManager
        @plugins = {}

        # Adds a plugin to the list of plugins, we expect a hash like:
        #
        #    {:type => "base",
        #     :class => foo.new}
        #
        # or like:
        #    {:type => "base",
        #     :class => "Foo::Bar"}
        #
        # In the event that we already have a class with the given type
        # an exception will be raised.
        #
        # If the :class passed is a String then we will delay instantiation
        # till the first time someone asks for the plugin, this is because most likely
        # the registration gets done by inherited() hooks, at which point the plugin class is not final.
        #
        # If we were to do a .new here the Class initialize method would get called and not
        # the plugins, we there for only initialize the classes when they get requested via []
        #
        # By default all plugin instances are cached and returned later so there's
        # always a single instance.  You can pass :single_instance => false when
        # calling this to instruct it to always return a new instance when a copy
        # is requested.  This only works with sending a String for :class.
        def self.<<(plugin)
            plugin[:single_instance] = true unless plugin.include?(:single_instance)

            type = plugin[:type]
            klass = plugin[:class]
            single = plugin[:single_instance]

            raise("Plugin #{type} already loaded") if @plugins.include?(type)


            # If we get a string then store 'nil' as the instance, signalling that we'll
            # create the class later on demand.
            if klass.is_a?(String)
                @plugins[type] = {:loadtime => Time.now, :class => klass, :instance => nil, :single => single}
                Log.debug("Registering plugin #{type} with class #{klass} single_instance: #{single}")
            else
                @plugins[type] = {:loadtime => Time.now, :class => klass.class, :instance => klass, :single => true}
                Log.debug("Registering plugin #{type} with class #{klass.class} single_instance: true")
            end
        end

        # Removes a plugim the list
        def self.delete(plugin)
            @plugins.delete(plugin) if @plugins.include?(plugin)
        end

        # Finds out if we have a plugin with the given name
        def self.include?(plugin)
            @plugins.include?(plugin)
        end

        # Provides a list of plugins we know about
        def self.pluginlist
            @plugins.keys
        end

        # deletes all registered plugins
        def self.clear
            @plugins.clear
        end

        # Gets a plugin by type
        def self.[](plugin)
            raise("No plugin #{plugin} defined") unless @plugins.include?(plugin)

            klass = @plugins[plugin][:class]

            if @plugins[plugin][:single]
                # Create an instance of the class if one hasn't been done before
                if @plugins[plugin][:instance] == nil
                    Log.debug("Returning new plugin #{plugin} with class #{klass}")
                    @plugins[plugin][:instance] = create_instance(klass)
                else
                    Log.debug("Returning cached plugin #{plugin} with class #{klass}")
                end

                @plugins[plugin][:instance]
            else
                Log.debug("Returning new plugin #{plugin} with class #{klass}")
                create_instance(klass)
            end
        end

        # use eval to create an instance of a class
        def self.create_instance(klass)
            begin
                eval("#{klass}.new")
            rescue Exception => e
                raise("Could not create instance of plugin #{klass}: #{e}")
            end
        end

        # Loads a class from file by doing some simple search/replace
        # on class names and then doing a require.
        def self.loadclass(klass)
            fname = klass.gsub("::", "/").downcase + ".rb"

            Log.debug("Loading #{klass} from #{fname}")

            load fname
        rescue Exception => e
            Log.error("Failed to load #{klass}: #{e}")
        end

        # Grep's over the plugin list and returns the list found
        def self.grep(regex)
            @plugins.keys.grep regex
        end
    end
end
# vi:tabstop=4:expandtab:ai
