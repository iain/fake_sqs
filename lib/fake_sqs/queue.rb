require 'securerandom'

module FakeSQS

  ReadCountOutOfRange = Class.new(RuntimeError)

  class Queue

    attr_reader :name, :messages, :message_factory, :messages_in_flight

    def initialize(options = {})
      @name = options.fetch("QueueName")
      @message_factory = options.fetch(:message_factory)
      reset
    end

    def send_message(options = {})
      message = message_factory.new(options)
      messages << message
      message
    end

    def receive_message(options = {})
      amount = Integer options.fetch("MaxNumberOfMessages") { "1" }

      fail ReadCountOutOfRange, amount if amount > 10

      return {} if messages.empty?

      result = {}

      actual_amount = amount > size ? size : amount

      actual_amount.times do
        message = messages.delete_at(rand(size))
        receipt = generate_receipt
        messages_in_flight[receipt] = message
        result[receipt] = message
      end

      result
    end

    def delete_message(receipt)
      message = messages_in_flight.delete(receipt)
    end

    def reset
      @messages = []
      @messages_in_flight = {}
    end

    def expire
      @messages += messages_in_flight.values
      @messages_in_flight = {}
    end

    def size
      messages.size
    end

    def generate_receipt
      SecureRandom.hex
    end

  end
end
