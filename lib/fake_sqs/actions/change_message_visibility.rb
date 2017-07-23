module FakeSQS
  module Actions
    class ChangeMessageVisibility

      def initialize(options = {})
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue_name, params)
        queue = @queues.get(queue_name)
        visibility = params.fetch("VisibilityTimeout")
        receipt = params.fetch("ReceiptHandle")

        queue.change_message_visibility(receipt, visibility.to_i)

        @responder.call :ChangeMessageVisibility
      end

    end
  end
end
