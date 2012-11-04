module FakeSQS
  class QueueFactory

    attr_reader :message_factory, :queue

    def initialize(options = {})
      @message_factory = options.fetch(:message_factory)
      @queue = options.fetch(:queue)
    end

    def new(options)
      queue.new(options.merge(:message_factory => message_factory))
    end

  end
end
