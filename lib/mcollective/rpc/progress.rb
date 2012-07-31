module MCollective
  module RPC
    # Class that shows a progress bar, currently only supports a twirling
    # progress bar.
    #
    # You can specify a size for the progress bar if you want if you dont
    # it will use the helper functions to figure out terminal dimensions
    # and draw an appropriately sized bar
    #
    # p = Progress.new
    # 100.times {|i| print p.twirl(i+1, 100) + "\r"};puts
    #
    #  * [ ==================================================> ] 100 / 100
    class Progress
      def initialize(size=nil)
        @twirl = ['|', '/', '-', "\\", '|', '/', '-', "\\"]
        @twirldex = 0

        if size
          @size = size
        else
          cols = Util.terminal_dimensions[0] - 22

          # Defaults back to old behavior if it
          # couldn't figure out the size or if
          # its more than 60 wide
          if cols <= 0
            @size = 0
          elsif cols > 60
            @size = 60
          else
            @size = cols
          end
        end
      end

      def twirl(current, total)
        # if the size is negative there is just not enough
        # space on the terminal, return a simpler version
        return "\r#{current} / #{total}" if @size == 0

        if current == total
          txt = "\r %s [ " % Util.colorize(:green, "*")
        else
          txt = "\r %s [ " % Util.colorize(:red, @twirl[@twirldex])
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
