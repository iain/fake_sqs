module FakeSQS
  module Actions
    class ReceiveMessage

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(name, params)
        queue = @queues.get(name)
        messages = queue.receive_message(params)
        @responder.call :ReceiveMessage do |xml|
          messages.each do |receipt, message|
            message.receive_count += 1
            xml.Message do
              xml.MessageId message.id
              xml.ReceiptHandle receipt
              xml.MD5OfBody message.md5
              xml.Body message.body
              xml.Attribute do
                xml.Name 'ApproximateReceiveCount'
                xml.Value message.receive_count
              end
            end
          end
        end
      end

    end
  end
end
