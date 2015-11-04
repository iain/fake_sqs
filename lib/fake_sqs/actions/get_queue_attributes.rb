module FakeSQS
  module Actions
    class GetQueueAttributes

      def initialize(request, options = {})
        @request   = request
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(params)
        queue_name = params['queue']
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
