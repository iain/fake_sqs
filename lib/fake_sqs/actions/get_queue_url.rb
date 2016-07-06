module FakeSQS
  module Actions
    class GetQueueUrl

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
        @request   = options.fetch(:request)
      end

      def call(params)
        name = params.fetch("QueueName")
        queue = @queues.get(name, params)
        @responder.call :GetQueueUrl do |xml|
          xml.QueueUrl @server.url_for(queue.name, {:host => @request.host, :port => @request.port})
        end
      end

    end
  end
end
