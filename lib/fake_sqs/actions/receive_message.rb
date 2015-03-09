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
            xml.Message do
              xml.MessageId message.id
              xml.ReceiptHandle receipt
              xml.MD5OfBody message.md5
              xml.MD5OfMessageAttributes message.message_attributes_md5
              xml.Body message.body
              message.message_attributes.each do |attribute|
                xml.MessageAttribute do
                  xml.Name attribute["Name"]
                  xml.Value do
                    xml.StringValue attribute["Value.StringValue"] if attribute["Value.StringValue"]
                    xml.BinaryValue attribute["Value.BinaryValue"] if attribute["Value.BinaryValue"]
                    xml.DataType attribute["Value.DataType"]
                  end
                end
              end
            end
          end
        end
      end

    end
  end
end
