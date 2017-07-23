module FakeSQS
  module Actions
    class PurgeQueue

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue_name, params)
        queue = @queues.get(queue_name)
        queue.reset()
        @responder.call :PurgeQueue
      end

    end
  end
end
