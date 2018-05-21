require "yaml/store"

module FakeSQS
  class FileDatabase

    attr_reader :filename

    def initialize(filename)
      @filename = filename
      @queue_objects = {}
      unless thread_safe_store?
        # before ruby 2.4, YAML::Store cannot be declared thread safe
        #
        # without that declaration, attempting to have some thread B enter a
        # store.transaction on the store while another thread A is in one
        # already will raise an error unnecessarily.
        #
        # to prevent this, we'll use our own mutex around store.transaction,
        # so only one thread can even _try_ to enter the transaction at a
        # time.
        @store_mutex = Mutex.new
        @store_mutex_owner = nil
      end
    end

    def load
      transaction do
        store["queues"] ||= {}
      end
    end

    def transaction
      if thread_safe_store? || store_mutex_owned?
        # if we already own the store mutex, we can expect the next line to
        # raise (appropriately) when we try to nest transactions in the store.
        # but if we took the other branch, the # @store_mutex.synchronize call
        # would self-deadlock before we could raise the error.
        store.transaction do
          yield
        end
      else
        # we still need to use an inner store.transaction block because it does
        # more than just lock synchronization. it's unfortunately inefficient,
        # but this isn't a production-oriented library.
        @store_mutex.synchronize do
          begin
            # allows us to answer `store_mutex_owned?` above
            @store_mutex_owner = Thread.current
            store.transaction do
              yield
            end
          ensure
            @store_mutex_owner = nil
          end
        end
      end
    end

    def reset
      transaction do
        store["queues"] = {}
      end
      @queue_objects = {}
    end

    def []=(key, value)
      storage[key] = value.to_yaml
    end

    def [](key)
      value = storage[key]
      if value
        deserialize(key)
      else
        value
      end
    end

    def each(&block)
      storage.each do |key, value|
        yield key, deserialize(key)
      end
    end

    def select(&block)
      new_list = storage.select do |key, value|
        yield key, deserialize(key)
      end
      Hash[new_list.map { |key, value| [key, deserialize(key)] }]
    end

    def delete(key)
      @queue_objects.delete(key)
      storage.delete(key)
    end

    def values
      storage.map { |key, value|
        deserialize(key)
      }
    end

    private

    def deserialize(key)
      @queue_objects[key] ||= Queue.new(storage[key].merge(message_factory: Message))
    end

    def storage
      store["queues"]
    end

    def thread_safe_store?
      Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.4")
    end

    def store_mutex_owned?
      # this could be just "@store_mutex && @store_mutex.owned?" in ruby 2.x,
      # but we still support 1.9.3 which doesn't have the "owned?" method
      @store_mutex_owner == Thread.current
    end

    def store
      @store ||= thread_safe_store? ?
        YAML::Store.new(filename, true) :
        YAML::Store.new(filename)
    end
  end
end
