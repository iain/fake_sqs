module FakeSQS

  QueueNameExists  = Class.new(RuntimeError)
  NonExistentQueue = Class.new(RuntimeError)

  class Queues

    attr_reader :queue_factory, :database

    def initialize(options = {})
      @queue_factory = options.fetch(:queue_factory)
      @database = options.fetch(:database)
      @database.load
    end

    def create(name, options = {})
      return database[name] if database[name]
      queue = queue_factory.new(options)
      database[name] = queue
    end

    def delete(name, options = {})
      if database[name]
        database.delete(name)
      else
        fail NonExistentQueue, name
      end
    end

    def list(options = {})
      if (prefix = options["QueueNamePrefix"])
        database.select { |name, queue| name.start_with?(prefix) }.values
      else
        database.values
      end
    end

    def get(name, options = {})
      if (db = database[name])
        db
      else
        fail NonExistentQueue, name
      end
    end

    def transaction
      database.transaction do
        yield
      end
    end

    def save(queue)
      database[queue.name] = queue
    end

    def reset
      database.reset
    end

    def timeout_messages!
      transaction do
        database.each { |name,queue| queue.timeout_messages! }
      end
    end

    def expire
      transaction do
        database.each { |name, queue| queue.expire }
      end
    end

  end
end
