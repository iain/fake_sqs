module FakeSQS
  module Actions
    class SendMessage

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue_name, params)
        queue = @queues.get(queue_name)
        message = queue.send_message(params)
        @responder.call :SendMessage do |xml|
          xml.MD5OfMessageBody message.md5
          xml.MessageId message.id
        end
      end

    end
  end
end
