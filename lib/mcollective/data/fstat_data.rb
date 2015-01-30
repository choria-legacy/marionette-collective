module MCollective
  module Data
    class Fstat_data<Base
      query do |file|
        result[:name] = file
        result[:output] = "not present"
        result[:type] = "unknown"
        result[:mode] = "0000"
        result[:present] = 0
        result[:size] = 0
        result[:mtime] = 0
        result[:ctime] = 0
        result[:atime] = 0
        result[:mtime_seconds] = 0
        result[:ctime_seconds] = 0
        result[:atime_seconds] = 0
        result[:md5] = 0
        result[:uid] = 0
        result[:gid] = 0


        if File.exists?(file)
          result[:output] = "present"
          result[:present] = 1

          if File.symlink?(file)
            stat = File.lstat(file)
          else
            stat = File.stat(file)
          end

          [:size, :uid, :gid].each do |item|
            result[item] = stat.send(item)
          end

          [:mtime, :ctime, :atime].each do |item|
            result[item] = stat.send(item).strftime("%F %T")
            result["#{item}_seconds".to_sym] = stat.send(item).to_i
            result["#{item}_age".to_sym] = Time.now.to_i - stat.send(item).to_i
          end

          result[:mode] = "%o" % [stat.mode]
          result[:md5] = Digest::MD5.hexdigest(File.read(file)) if stat.file?

          result[:type] = "directory" if stat.directory?
          result[:type] = "file" if stat.file?
          result[:type] = "symlink" if stat.symlink?
          result[:type] = "socket" if stat.socket?
          result[:type] = "chardev" if stat.chardev?
          result[:type] = "blockdev" if stat.blockdev?
        end
      end
    end
  end
end

