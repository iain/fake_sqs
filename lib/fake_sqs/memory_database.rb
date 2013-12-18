require "forwardable"

module FakeSQS
  class MemoryDatabase
    extend Forwardable

    def_delegators :@queues,
      :[], :[]=, :delete, :each, :select, :values

    def initialize
      @in_transaction = false
    end

    def load
      @queues = {}
    end

    def transaction
      if @in_transaction
        raise "Already in transaction"
      else
        @in_transaction = true
        begin
          yield
        ensure
          @in_transaction = false
        end
      end
    end

    def reset
      @queues = {}
    end

  end
end
