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
        messages = queue.receive_message(params.dotted_to_nested_hash)
        @responder.call :ReceiveMessage do |xml|
          messages.each do |receipt, message|
            xml.Message do
              xml.MessageId message.id
              xml.ReceiptHandle receipt
              xml.MD5OfBody message.md5
              xml.Body message.body

              # TODO: should only return the requested attribtues
              message.message_attributes.each do |index, attribute|
                xml.MessageAttribute do
                  xml.Name attribute['Name']
                  xml.Value do |value|
                    xml.DataType attribute['Value']['DataType']

                    # TODO: other types exist
                    xml.StringValue attribute['Value']['StringValue']
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
