module FakeSQS

  QueueNameExists  = Class.new(RuntimeError)
  NonExistentQueue = Class.new(RuntimeError)

  class Queues

    attr_reader :queues, :queue_factory

    def initialize(options = {})
      @queue_factory = options.fetch(:queue_factory)
      reset
    end

    def create(name, options = {})
      if queues[name]
        fail QueueNameExists, name
      else
        queue = queue_factory.new(options)
        queues[name] = queue
      end
    end

    def delete(name, options = {})
      if queues[name]
        queues.delete(name)
      else
        fail NonExistentQueue, name
      end
    end

    def list(options = {})
      if (prefix = options["QueueNamePrefix"])
        queues.select { |name, queue| name =~ /^#{prefix}/ }.values
      else
        queues.values
      end
    end

    def get(name, options = {})
      if queues[name]
        queues[name]
      else
        fail NonExistentQueue, name
      end
    end

    def reset
      @queues = {}
    end

    def expire
      queues.each { |name, queue| queue.expire }
    end

  end
end
