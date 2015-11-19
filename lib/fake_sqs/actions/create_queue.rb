require 'fake_sqs/helpers'

module FakeSQS
  module Actions
    class CreateQueue

      def initialize(options = {})
        @request   = options.fetch(:request)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(params)
        name = params.fetch("QueueName")
        queue = @queues.create(name, params)
        @responder.call :CreateQueue do |xml|
          xml.QueueUrl FakeSQS::Helpers.queue_url(@request, queue.name)
        end
      end

    end
  end
end
