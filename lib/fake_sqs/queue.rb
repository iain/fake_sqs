require 'monitor'
require 'securerandom'
require 'fake_sqs/collection_view'
require 'json'

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
        "ApproximateNumberOfMessages" => published_size,
        "ApproximateNumberOfMessagesNotVisible" => @messages_in_flight.size,
      )
    end

    def send_message(options = {})
      with_lock do
        message = options.fetch(:message){ message_factory.new(options) }
        if message
          @messages[message.receipt] = message
        end
        message
      end
    end

    def receive_message(options = {})
      amount = Integer options.fetch("MaxNumberOfMessages") { "1" }
      visibility_timeout = Integer options.fetch("VisibilityTimeout") { default_visibility_timeout }

      fail ReadCountOutOfRange, amount if amount > 10

      return {} if @messages.empty?

      result = {}

      with_lock do
        actual_amount = amount > published_size ? published_size : amount
        published_messages = @messages.values.select { |m| m.published? }

        actual_amount.times do
          message = published_messages.delete_at(rand(published_size))
          @messages.delete(message.receipt)
          unless check_message_for_dlq(message, options)
            message.expire_at(visibility_timeout)
            message.receive!
            @messages_in_flight[message.receipt] = message
            result[message.receipt] = message
          end
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
          @messages[receipt] = message
          @messages_in_flight.delete(receipt)
        end
      end
    end

    def change_message_visibility(receipt, visibility)
      with_lock do
        message = @messages_in_flight[receipt]
        raise MessageNotInflight unless message

        if visibility == 0
          message.expire!
          @messages[receipt] = message
          @messages_in_flight.delete(receipt)
        else
          message.expire_at(visibility)
        end
      end
    end

    def check_message_for_dlq(message, options={})
      if redrive_policy = queue_attributes["RedrivePolicy"] && JSON.parse(queue_attributes["RedrivePolicy"])
        dlq = options[:queues].list.find{|queue| queue.arn == redrive_policy["deadLetterTargetArn"]}
        if dlq && message.approximate_receive_count >= redrive_policy["maxReceiveCount"].to_i
          dlq.send_message(message: message)
          message.expire!
          true
        end
      end
    end

    def delete_message(receipt)
      with_lock do
        @messages.delete(receipt)
        @messages_in_flight.delete(receipt)
      end
    end

    def reset
      with_lock do
        @messages = {}
        @messages_view = FakeSQS::CollectionView.new(@messages)
        reset_messages_in_flight
      end
    end

    def expire
      with_lock do
        @messages.merge!(@messages_in_flight)
        @messages_in_flight.clear()
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
      @messages.size
    end

    def published_size
      @messages.values.select { |m| m.published? }.size
    end

    def with_lock
      @lock.synchronize do
        yield
      end
    end

  end
end
