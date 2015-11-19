module FakeSQS
  module Actions
    class DeleteMessage

      def initialize(options = {})
        @request   = options.fetch(:request)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(name, params)
        queue = @queues.get(name)

        receipt = params.fetch("ReceiptHandle")
        queue.delete_message(receipt)
        @responder.call :DeleteMessage
      end

    end
  end
end
