module FakeSQS
  module Actions
    class GetQueueAttributes

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue_name, params)
        queue = @queues.get(queue_name)
        @responder.call :GetQueueAttributes do |xml|
          queue.attributes.each do |name, value|
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
