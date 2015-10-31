require "forwardable"
require "thread"

module FakeSQS
  class MemoryDatabase
    extend Forwardable

    def_delegators :@queues,
      :[], :[]=, :delete, :each, :select, :values

    def initialize
      @semaphore = Mutex.new
    end

    def load
      @queues = {}
    end

    def transaction
      @semaphore.synchronize do
        yield
      end
    end

    def reset
      @queues = {}
    end

  end
end
