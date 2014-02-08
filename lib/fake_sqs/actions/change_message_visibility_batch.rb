module FakeSQS
  module Actions
    class ChangeMessageVisibilityBatch

      def initialize(options = {})
        @queues = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue, params)
        keys = params.keys.map do |key|
          case key
            when /^ChangeMessageVisibilityBatchRequestEntry\.(\w+)\.Id$/
              $1
          end
        end.compact

        messages = keys.map do |key|
          receipt = params.fetch("ChangeMessageVisibilityBatchRequestEntry.#{key}.ReceiptHandle")
          timeout = params.fetch("ChangeMessageVisibilityBatchRequestEntry.#{key}.VisibilityTimeout").to_i
          @queues.get(queue).change_message_visibility(receipt, timeout)
          params.fetch("ChangeMessageVisibilityBatchRequestEntry.#{key}.Id")
        end

        @responder.call :ChangeMessageVisibilityBatch do |xml|
          xml.ChangeMessageVisibilityBatchResult do
            messages.each do |message|
              xml.ChangeMessageVisibilityBatchResultEntry do
                xml.Id message
              end
            end
          end
        end
      end

    end
  end
end