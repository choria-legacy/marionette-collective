module MCollective
    module Agent
        class Test<RPC::Agent
            metadata    :name        => "test",
                        :description => "description",
                        :author      => "Me",
                        :license     => "license",
                        :version     => "version",
                        :url         => "homepage",
                        :timeout     => 5

            action "external_test" do
                validate :message, String

                implemented_by "/tmp/echo.pl"
            end
        end
    end
end
