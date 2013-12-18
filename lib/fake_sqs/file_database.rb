require "yaml/store"

module FakeSQS
  class FileDatabase

    attr_reader :filename

    def initialize(filename)
      @filename = filename
      @queue_objects = {}
    end

    def load
      transaction do
        store["queues"] ||= {}
      end
    end

    def transaction
      store.transaction do
        yield
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

    def store
      @store ||= YAML::Store.new(filename)
    end

  end
end
