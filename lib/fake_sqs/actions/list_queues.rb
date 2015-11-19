require 'fake_sqs/helpers'

module FakeSQS
  module Actions
    class ListQueues

      def initialize(options = {})
        @request   = options.fetch(:request)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(params)
        found = @queues.list(params)
        @responder.call :ListQueues do |xml|
          found.each do |queue|
            xml.QueueUrl FakeSQS::Helpers.queue_url(@request, queue.name)
          end
        end
      end

    end
  end
end
