module FakeSQS
  module Actions
    class CreateQueue

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(params)
        name = params.fetch("QueueName")

        # Extract any attributes into a simple hash structure
        attributes = params.each_with_object({}) do |(key, value), attrs|
          next unless key =~ /\AAttribute\.(\d+)\.Name\z/
          attrs[value] = params.fetch("Attribute.#{$1}.Value")
        end

        queue = @queues.create(name, params.merge("Attributes" => attributes))
        @responder.call :CreateQueue do |xml|
          xml.QueueUrl @server.url_for(queue.name)
        end
      end

    end
  end
end
