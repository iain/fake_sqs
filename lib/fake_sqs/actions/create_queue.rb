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
        queue = @queues.create(name, params)
        @responder.call :CreateQueue do |xml|
          xml.QueueUrl @server.url_for(queue.name)
        end
      end

    end
  end
end
