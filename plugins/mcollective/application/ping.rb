# encoding: utf-8
module MCollective
  class Application::Ping<Application
    description "Ping all nodes"

    option :graph,
           :description    => "Shows a graph of ping distribution",
           :arguments      => ["--graph", "-g"],
           :default        => false,
           :type           => :bool

    # Convert the times structure into a array representing
    # buckets of responses in 50 ms intervals.  Return a small
    # sparkline graph using UTF8 characters
    def spark(resp_times)
      return "" unless configuration[:graph] || Config.instance.pluginconf["rpc.graph"]

      ticks=%w[▁ ▂ ▃ ▄ ▅ ▆ ▇]

      histo = {}

      # round each time to its nearest 50ms
      # and keep a count for each 50ms
      resp_times.each do |time|
        time = Integer(time + 50 - (time % 50))
        histo[time] ||= 0
        histo[time] += 1
      end

      # set the 50ms intervals that saw no traffic to 0
      ((histo.keys.max - histo.keys.min) / 50).times do |i|
        time = (i * 50) + histo.keys.min
        histo[time] = 0 unless histo[time]
      end

      # get a numerically sorted list of times
      histo = histo.keys.sort.map{|k| histo[k]}

      range = histo.max - histo.min
      scale = ticks.size - 1
      distance = histo.max.to_f / scale

      histo.map do |val|
        tick = (val / distance).round
        tick = 0 if tick < 0

        ticks[tick]
      end.join
    end

    def main
      client = MCollective::Client.new(options)

      start = Time.now.to_f
      times = []

      client.req("ping", "discovery") do |resp|
        times << (Time.now.to_f - start) * 1000

        puts "%-40s time=%.2f ms" % [resp[:senderid], times.last]
      end

      puts("\n\n---- ping statistics ----")

      if times.size > 0
        sum = times.inject(0){|acc,i|acc +i}
        avg = sum / times.length.to_f

        puts "%d replies max: %.2f min: %.2f avg: %.2f %s" % [times.size, times.max, times.min, avg, spark(times)]
      else
        puts("No responses received")
      end

      halt client.stats
    end
  end
end
