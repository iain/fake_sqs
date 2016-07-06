module FakeSQS
  module Actions
    class ListQueues

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
        @request   = options.fetch(:request)
      end

      def call(params)
        found = @queues.list(params)
        @responder.call :ListQueues do |xml|
          found.each do |queue|
            xml.QueueUrl @server.url_for(queue.name, {:host => @request.host, :port => @request.port})
          end
        end
      end

    end
  end
end
