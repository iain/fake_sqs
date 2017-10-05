module FakeSQS
  module Actions
    class ReceiveMessage

      MAX_WAIT_TIME_SECONDS = 20

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
        @start_ts  = Time.now.to_f
        @satisfied = false
      end

      def call(queue_name, params)
        queue = @queues.get(queue_name)
        filtered_attribute_names = []
        params.select{|k,v | k =~ /AttributeName\.\d+/}.each do |key, value|
          filtered_attribute_names << value
        end
        messages = queue.receive_message(params.merge(queues: @queues))
        @satisfied = !messages.empty? || expired?(queue, params)
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

      def satisfied?
        @satisfied
      end

      protected
      def elapsed
        Time.now.to_f - @start_ts
      end

      def expired?(queue, params)
        wait_time_seconds = Integer params.fetch("WaitTimeSeconds") {
          queue.queue_attributes.fetch("ReceiveMessageWaitTimeSeconds") { 0 }
        }
        wait_time_seconds <= 0 ||
        elapsed >= wait_time_seconds ||
        elapsed >= MAX_WAIT_TIME_SECONDS
      end
    end
  end
end
