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
        def self.<<(plugin)
            type = plugin[:type]
            klass = plugin[:class]
    
            raise("Plugin #{type} already loaded") if @plugins.include?(type)
    

	    if klass.is_a?(String)
	    	Log.instance.debug("Registering plugin #{type} with class #{klass}")
            	@plugins[type] = {:loadtime => Time.now, :class => klass, :instance => nil}
	    else
	    	Log.instance.debug("Registering plugin #{type} with class #{klass.class}")
            	@plugins[type] = {:loadtime => Time.now, :class => klass.class, :instance => klass}
	    end
        end
    
        # Provides a list of plugins we know about
        def self.pluginlist
            self.plugins.keys
        end
    
        # Gets a plugin by type
        def self.[](plugin)
            raise("No plugin #{plugin} defined") unless @plugins.include?(plugin)

	    klass = @plugins[plugin][:class]

	    # Create an instance of the class if one hasn't been done before
	    if @plugins[plugin][:instance] == nil
                @plugins[plugin][:instance] = eval("#{klass}.new")
            end

	    Log.instance.debug("Returning plugin #{plugin} with class #{klass}")

            @plugins[plugin][:instance]
        end
    
        # Loads a class from file by doing some simple search/replace
        # on class names and then doing a require.
        def self.loadclass(klass)
            fname = klass.gsub("::", "/").downcase

	    Log.instance.debug("Loading #{klass} from #{fname}")
    
            require fname
        end
    end
end
