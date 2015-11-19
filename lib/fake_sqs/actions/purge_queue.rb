module FakeSQS
  module Actions
    class PurgeQueue

      def initialize(options = {})
        @request   = options.fetch(:request)
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
