module FakeSQS
  module Actions
    class ReceiveMessage

      def initialize(request, options = {})
        @request   = request
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(params)
        name = params['queue']
        queue = @queues.get(name)
        messages = queue.receive_message(params)
        @responder.call :ReceiveMessage do |xml|
          messages.each do |receipt, message|
            xml.Message do
              xml.MessageId message.id
              xml.ReceiptHandle receipt
              xml.MD5OfBody message.md5
              xml.Body message.body
            end
          end
        end
      end

    end
  end
end
