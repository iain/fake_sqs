module FakeSQS
  module Actions
    class PurgeQueue

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(name, params)
        queue = @queues.get(name)
        queue.reset()
        @responder.call :PurgeQueue
      end

    end
  end
end
