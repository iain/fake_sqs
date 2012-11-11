module FakeSQS
  module Actions
    class ListQueues

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(params)
        found = @queues.list(params)
        @responder.call :ListQueues do |xml|
          found.each do |queue|
            xml.QueueUrl @server.url_for(queue.name)
          end
        end
      end

    end
  end
end
