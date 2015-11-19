module FakeSQS
  module Actions
    class SetQueueAttributes

      def initialize(options = {})
        @request   = options.fetch(:request)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue_name, params)
        queue = @queues.get(queue_name)
        results = {}
        params.each do |key, value|
          if key =~ /\AAttribute\.(\d+)\.Name\z/
            results[value] = params.fetch("Attribute.#{$1}.Value")
          end
        end
        queue.add_queue_attributes(results)
        @queues.save(queue)
        @responder.call :SetQueueAttributes
      end

    end
  end
end
