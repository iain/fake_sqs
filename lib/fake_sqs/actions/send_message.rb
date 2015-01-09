module FakeSQS
  module Actions
    class SendMessage

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(name, params)
        queue = @queues.get(name)
        message = queue.send_message(params.dotted_to_nested_hash)
        @responder.call :SendMessage do |xml|
          xml.MD5OfMessageBody message.md5
          xml.MessageId message.id
        end
      end

    end
  end
end
