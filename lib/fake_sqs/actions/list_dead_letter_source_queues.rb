module FakeSQS
  module Actions
    class ListDeadLetterSourceQueues

      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(name, params)
        queue_arn = @queues.get(name).arn
        queue_urls = @queues.list.select do |queue|
          redrive_policy = queue.attributes.fetch("RedrivePolicy", nil)
          redrive_policy && redrive_policy =~ /deadLetterTargetArn\":\"#{queue_arn}/
        end
        @responder.call :ListDeadLetterSourceQueues do |xml|
          queue_urls.each do |queue|
            xml.QueueUrl @server.url_for(queue.name)
          end
        end
      end
    end
  end
end
