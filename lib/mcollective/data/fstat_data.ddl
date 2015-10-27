metadata    :name        => "File Stat",
            :description => "Retrieve file stat data for a given file",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "ASL 2.0",
            :version     => "1.0",
            :url         => "https://docs.puppetlabs.com/mcollective/",
            :timeout     => 1

dataquery :description => "File stat information" do
    input :query,
          :prompt => "File Name",
          :description => "Valid File Name",
          :type => :string,
          :validation => /.+/,
          :maxlength => 120

    output :name,
           :description => "File name",
           :display_as => "Name"

    output :output,
           :description => "Human readable information about the file",
           :display_as => "Status"

    output :present,
           :description => "Indicates if the file exist using 0 or 1",
           :display_as => "Present"

    output :size,
           :description => "File size",
           :display_as => "Size"

    output :mode,
           :description => "File mode",
           :display_as => "Mode"

    output :md5,
           :description => "File MD5 digest",
           :display_as => "MD5"

    output :mtime,
           :description => "File modification time",
           :display_as => "Modification time"

    output :ctime,
           :description => "File change time",
           :display_as => "Change time"

    output :atime,
           :description => "File access time",
           :display_as => "Access time"

    output :mtime_seconds,
           :description => "File modification time in seconds",
           :display_as => "Modification time"

    output :ctime_seconds,
           :description => "File change time in seconds",
           :display_as => "Change time"

    output :atime_seconds,
           :description => "File access time in seconds",
           :display_as => "Access time"

    output :mtime_age,
           :description => "File modification age in seconds",
           :display_as => "Modification age"

    output :ctime_age,
           :description => "File change age in seconds",
           :display_as => "Change age"

    output :atime_age,
           :description => "File access age in seconds",
           :display_as => "Access age"

    output :uid,
           :description => "File owner",
           :display_as => "Owner"

    output :gid,
           :description => "File group",
           :display_as => "Group"

    output :type,
           :description => "File type",
           :display_as => "Type"
end

