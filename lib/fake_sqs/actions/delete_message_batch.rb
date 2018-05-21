module FakeSQS
  module Actions
    class DeleteMessageBatch

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue_name, params)
        queue = @queues.get(queue_name)
        receipts = params.select { |k,v| k =~ /DeleteMessageBatchRequestEntry\.\d+\.ReceiptHandle/ }

        deleted = receipts.map { |key, value|
          id = key.split('.')[1]
          queue.delete_message(value) # Broken, can only delete in-flight messages
          params.fetch("DeleteMessageBatchRequestEntry.#{id}.Id")
        }

        @responder.call :DeleteMessageBatch do |xml|
          deleted.each do |id|
            xml.DeleteMessageBatchResultEntry do
              xml.Id id
            end
          end
        end
      end

    end
  end
end
