module MCollective
    module RPC 
        # Class that shows a progress bar, currently only supports a twirling 
        # progress bar.
        #
        # p = Progress.new(60)
        # 100.times {|i| print p.twirl(i+1, 100) + "\r"};puts       
        #
        #  * [ ==================================================> ] 100 / 100
        class Progress
            def initialize(size)
                @twirl = ['|', '/', '-', "\\", '|', '/', '-', "\\"]
                @twirldex = 0
                @size = size
            end

            def twirl(current, total)
                if current == total
                    txt = "\r * [ "
                else
                    txt = "\r #{@twirl[@twirldex]} [ "
                end

                dashes = ((current.to_f / total) * @size).round

                dashes.times { txt << "=" }
                txt << ">"

                (@size - dashes).times { txt << " " }

                txt << " ] #{current} / #{total}"

                @twirldex == 7 ? @twirldex = 0 : @twirldex += 1

                return txt
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
