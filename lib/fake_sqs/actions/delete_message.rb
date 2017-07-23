module FakeSQS
  module Actions
    class DeleteMessage

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue_name, params)
        queue = @queues.get(queue_name)

        receipt = params.fetch("ReceiptHandle")
        queue.delete_message(receipt)
        @responder.call :DeleteMessage
      end

    end
  end
end
