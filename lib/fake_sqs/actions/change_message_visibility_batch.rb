module FakeSQS
  module Actions
    class ChangeMessageVisibilityBatch

      def initialize(options = {})
        @queues = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue_name, params)
        queue = @queues.get(queue_name)

        keys = params.keys.map do |key|
          case key
            when /^ChangeMessageVisibilityBatchRequestEntry\.(\w+)\.Id$/
              $1
          end
        end.compact

        ids = keys.map do |key|
          receipt = params.fetch("ChangeMessageVisibilityBatchRequestEntry.#{key}.ReceiptHandle")
          timeout = params.fetch("ChangeMessageVisibilityBatchRequestEntry.#{key}.VisibilityTimeout").to_i
          queue.change_message_visibility(receipt, timeout)
          params.fetch("ChangeMessageVisibilityBatchRequestEntry.#{key}.Id")
        end

        @responder.call :ChangeMessageVisibilityBatch do |xml|
          ids.each do |id|
            xml.ChangeMessageVisibilityBatchResultEntry do
              xml.Id id
            end
          end
        end
      end

    end
  end
end
