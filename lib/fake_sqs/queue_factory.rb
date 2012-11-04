module FakeSQS
  class QueueFactory

    attr_reader :message_factory

    def initialize(options = {})
      @message_factory = options.fetch(:message_factory)
    end

    def new(options)
      Queue.new(options.merge(:message_factory => message_factory))
    end

  end
end
