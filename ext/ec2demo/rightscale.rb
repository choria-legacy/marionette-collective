require 'find'
 
if File.exists?("/var/spool/ec2/meta-data")
    Find.find("/var/spool/ec2/meta-data") do |path|
        filename = File.basename(path)
        factname = "ec2_#{filename}"
 
        factname.gsub!(/-/, "_")
 
        if File.file?(path)
            lines = File.readlines(path)
 
            if lines.size == 1
                Facter.add(factname) do
                    setcode { lines.first.chomp.to_s }
                end
            else
                lines.each_with_index do |line, i|
                    Facter.add("#{factname}_#{i}") do
                        setcode { lines[i].chomp }
                    end
                end
            end
        end
    end
end
 
if File.exists?("/var/spool/ec2/user-data.raw")
        lines = File.readlines("/var/spool/ec2/user-data.raw")
 
        lines.each do |l|
                if l.chomp =~ /(.+)=(.+)/
                    f = $1; v = $2
 
                    Facter.add(f) do
                        setcode { v }
                    end
                end
        end
end


