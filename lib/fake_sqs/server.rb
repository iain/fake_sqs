module FakeSQS
  class Server

    attr_reader :host, :port

    def initialize(options)
      @host = options.fetch(:host)
      @port = options.fetch(:port)
    end

    def url_for(queue_id)
      "http://#{host}:#{port}/#{queue_id}"
    end

  end
end
