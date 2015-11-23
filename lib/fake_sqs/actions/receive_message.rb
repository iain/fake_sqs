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
        filtered_attribute_names = []
        params.select{|k,v | k =~ /AttributeName\.\d+/}.each do |key, value|
          filtered_attribute_names << value
        end
        messages = queue.receive_message(params.merge(queues: @queues))
        @responder.call :ReceiveMessage do |xml|
          messages.each do |receipt, message|
            xml.Message do
              xml.MessageId message.id
              xml.ReceiptHandle receipt
              xml.MD5OfBody message.md5
              xml.Body message.body
              message.attributes.each do |name, value|
                if filtered_attribute_names.include?("All") || filtered_attribute_names.include?(name)
                  xml.Attribute do
                    xml.Name name
                    xml.Value value
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