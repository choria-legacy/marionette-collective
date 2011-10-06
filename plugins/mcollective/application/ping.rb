module MCollective
  class Application::Ping<Application
    description "Ping all nodes"

    def main
      client = MCollective::Client.new(options[:config])
      client.options = options

      start = Time.now.to_f
      times = []

      client.req("ping", "discovery") do |resp|
        times << (Time.now.to_f - start) * 1000

        printf("%-40s time=%.2f ms\n", resp[:senderid], times.last)
      end

      puts("\n\n---- ping statistics ----")

      if times.size > 0
        sum = times.inject(0){|acc,i|acc +i}
        avg = sum / times.length.to_f

        printf("%d replies max: %.2f min: %.2f avg: %.2f\n", times.size, times.max, times.min, avg)
      else
        puts("No responses received")
      end
    end
  end
end
