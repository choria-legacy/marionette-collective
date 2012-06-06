module MCollective
  module Generators
    class Base
      attr_accessor :meta, :plugin_name, :mod_name
      def initialize(name, description, author, license, version, url, timeout)
        @meta = {:name => name,
                 :description => description,
                 :author => author,
                 :license => license,
                 :version => version,
                 :url => url,
                 :timeout => timeout}
      end

      def create_metadata_string
        ddl_template = File.read(File.join(File.dirname(__FILE__), "templates", "ddl.erb"))
        ERB.new(ddl_template, nil, "-").result(binding)
      end

      def create_plugin_string
        plugin_template = File.read(File.join(File.dirname(__FILE__), "templates", "plugin.erb"))
        ERB.new(plugin_template, nil, "-").result(binding)
      end

      def write_plugins
        begin
          Dir.mkdir @plugin_name
          dirname = File.join(@plugin_name, @mod_name.downcase)
          Dir.mkdir dirname
          puts "Created plugin directory : #{@plugin_name}"

          File.open(File.join(dirname, "#{@plugin_name}.ddl"), "w"){|f| f.puts @ddl}
          puts "Created DDL file : #{File.join(dirname, "#{@plugin_name}.ddl")}"

          File.open(File.join(dirname, "#{@plugin_name}.rb"), "w"){|f| f.puts @plugin}
          puts "Created #{@mod_name} file : #{File.join(dirname, "#{@plugin_name}.rb")}"
        rescue Errno::EEXIST
          raise "cannot generate '#{@plugin_name}' : plugin directory already exists."
        rescue Exception => e
          FileUtils.rm_rf(@plugin_name) if File.directory?(@plugin_name)
          raise "cannot generate plugin - #{e}"
        end
      end
    end
  end
end
