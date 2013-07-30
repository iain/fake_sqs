module FakeSQS
  module Actions
    class SetQueueAttributes
      def initialize(options = {})
        @server    = options.fetch(:server)
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(queue_name, attributes)
        # Example attributes:
        # {"Action"=>"SetQueueAttributes", "Attribute.1.Name"=>"ReceiveMessageWaitTimeSeconds", "Attribute.1.Value"=>"20", "QueueUrl"=>"http://0.0.0.0:4568/infra-development-app-events-1500", "Timestamp"=>"2013-07-30T15:33:37Z", "Version"=>"2012-11-05", "splat"=>[], "captures"=>["infra-development-app-events-1500"], "queue"=>"infra-development-app-events-1500"}
        puts "Woot! #{queue_name}"
        puts "HaHa! #{attributes} :)"
      end

    end
  end
end
