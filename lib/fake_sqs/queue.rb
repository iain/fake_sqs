require 'securerandom'
require 'fake_sqs/collection_view'

module FakeSQS

  MessageNotInflight = Class.new(RuntimeError)
  ReadCountOutOfRange = Class.new(RuntimeError)
  ReceiptHandleIsInvalid = Class.new(RuntimeError)

  class Queue

    VISIBILITY_TIMEOUT = 30

    attr_reader :name, :message_factory, :arn, :queue_attributes

    def initialize(options = {})
      @message_factory = options.fetch(:message_factory)

      @name = options.fetch("QueueName")
      @arn = options.fetch("Arn") { "arn:aws:sqs:us-east-1:#{SecureRandom.hex}:#{@name}" }
      @queue_attributes = options.fetch("Attributes") { {} }
      @lock = Monitor.new
      reset
    end

    def to_yaml
      {
        "QueueName" => name,
        "Arn" => arn,
        "Attributes" => queue_attributes,
      }
    end

    def add_queue_attributes(attrs)
      queue_attributes.merge!(attrs)
    end

    def attributes
      queue_attributes.merge(
        "QueueArn" => arn,
        "ApproximateNumberOfMessages" => @messages.size,
        "ApproximateNumberOfMessagesNotVisible" => @messages_in_flight.size,
      )
    end

    def send_message(options = {})
      with_lock do
        message = message_factory.new(options)
        @messages << message
        message
      end
    end

    def receive_message(options = {})
      amount = Integer options.fetch("MaxNumberOfMessages") { "1" }

      fail ReadCountOutOfRange, amount if amount > 10

      return {} if @messages.empty?

      result = {}

      with_lock do
        actual_amount = amount > size ? size : amount

        actual_amount.times do
          message = @messages.delete_at(rand(size))
          message.expire_at(default_visibility_timeout)
          receipt = generate_receipt
          @messages_in_flight[receipt] = message
          result[receipt] = message
        end
      end

      result
    end

    def default_visibility_timeout
      if value = attributes['VisibilityTimeout']
        value.to_i
      else
        VISIBILITY_TIMEOUT
      end
    end

    def timeout_messages!
      with_lock do
        expired = @messages_in_flight.inject({}) do |memo,(receipt,message)|
          if message.expired?
            memo[receipt] = message
          end
          memo
        end
        expired.each do |receipt,message|
          message.expire!
          @messages << message
          delete_message(receipt)
        end
      end
    end

    def change_message_visibility(receipt, visibility)
      with_lock do
        message = @messages_in_flight[receipt]
        raise MessageNotInflight unless message

        if visibility == 0
          message.expire!
          @messages << message
          delete_message(receipt)
        else
          message.expire_at(visibility)
        end

      end
    end

    def delete_message(receipt)
      with_lock do
        @messages_in_flight.delete(receipt)
      end
    end

    def reset
      with_lock do
        @messages = []
        @messages_view = FakeSQS::CollectionView.new(@messages)
        reset_messages_in_flight
      end
    end

    def expire
      with_lock do
        @messages += @messages_in_flight.values
        reset_messages_in_flight
      end
    end

    def reset_messages_in_flight
      with_lock do
        @messages_in_flight = {}
        @messages_in_flight_view = FakeSQS::CollectionView.new(@messages_in_flight)
      end
    end

    def messages
      @messages_view
    end

    def messages_in_flight
      @messages_in_flight_view
    end

    def size
      messages.size
    end

    def generate_receipt
      SecureRandom.hex
    end

    def with_lock
      @lock.synchronize do
        yield
      end
    end

  end
end
