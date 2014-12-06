module FakeSQS
  module Actions
    class ListQueues

      def initialize(request, options = {})
        @request   = request
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(params)
        found = @queues.list(params)
        @responder.call :ListQueues do |xml|
          found.each do |queue|
            xml.QueueUrl queue_url(@request, queue.name)
          end
        end
      end

    end
  end
end
