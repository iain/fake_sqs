module FakeSQS
  module Actions
    class SendMessageBatch

      def initialize(options = {})
        @request   = options.fetch(:request)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(name, params)
        queue = @queues.get(name)

        messages = params.select { |k,v| k =~ /SendMessageBatchRequestEntry\.\d+\.MessageBody/ }

        results = {}

        messages.each do |key, value|
          id = key.split('.')[1]
          msg_id = params.fetch("SendMessageBatchRequestEntry.#{id}.Id")
          delay = params["SendMessageBatchRequestEntry.#{id}.DelaySeconds"]
          message = queue.send_message("MessageBody" => value, "DelaySeconds" => delay)
          results[msg_id] = message
        end

        @responder.call :SendMessageBatch do |xml|
          results.each do |msg_id, message|
            xml.SendMessageBatchResultEntry do
              xml.Id msg_id
              xml.MessageId message.id
              xml.MD5OfMessageBody message.md5
            end
          end
        end
      end

    end
  end
end
