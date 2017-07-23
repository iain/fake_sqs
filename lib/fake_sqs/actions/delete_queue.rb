module FakeSQS
  module Actions
    class DeleteQueue

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue_name, params = {})
        @queues.delete(queue_name, params)
        @responder.call :DeleteQueue
      end

    end
  end
end
