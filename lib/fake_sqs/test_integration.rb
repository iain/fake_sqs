require "net/http"

module FakeSQS
  class TestIntegration

    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def host
      option :sqs_endpoint
    end

    def port
      option :sqs_port
    end

    def start
      start! unless up?
      reset
    end

    def start!
      args = [ binfile, "-p", port.to_s, verbose, logging, "--database", database, { :out => out, :err => out } ].flatten.compact
      @pid = Process.spawn(*args)
      wait_until_up
    end

    def stop
      if @pid
        Process.kill("INT", @pid)
        Process.waitpid(@pid)
        @pid = nil
      else
        $stderr.puts "FakeSQS is not running"
      end
    end

    def reset
      connection.delete("/")
    end

    def expire
      connection.put("/", "")
    end

    def url
      "http://#{host}:#{port}"
    end

    def uri
      URI(url)
    end

    def up?
      @pid && connection.get("/ping").code.to_s == "200"
    rescue Errno::ECONNREFUSED
      false
    end

    private

    def option(key)
      options.fetch(key)
    end

    def database
      options.fetch(:database)
    end

    def verbose
      if debug?
        "--verbose"
      else
        "--no-verbose"
      end
    end

    def logging
      if (file = ENV["SQS_LOG"] || options[:log])
        [ "--log", file ]
      else
        []
      end
    end

    def wait_until_up(deadline = Time.now + 2)
      fail "FakeSQS didn't start in time" if Time.now > deadline
      unless up?
        sleep 0.01
        wait_until_up(deadline)
      end
    end

    def binfile
      File.expand_path("../../../bin/fake_sqs", __FILE__)
    end

    def out
      if debug?
        :out
      else
        "/dev/null"
      end
    end

    def connection
      @connection ||= Net::HTTP.new(host, port)
    end

    def debug?
      ENV["DEBUG"].to_s == "true" || options[:debug]
    end

  end
end
