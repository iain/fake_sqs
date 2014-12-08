module FakeSQS
  module Actions
    class SetQueueAttributes

      def initialize(request, options = {})
        @request   = request
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(params)
        name = params['name']
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
