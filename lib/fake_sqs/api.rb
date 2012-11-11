require 'fake_sqs/actions/create_queue'
require 'fake_sqs/actions/delete_queue'
require 'fake_sqs/actions/list_queues'
require 'fake_sqs/actions/get_queue_url'
require 'fake_sqs/actions/send_message'
require 'fake_sqs/actions/receive_message'
require 'fake_sqs/actions/delete_message'
require 'fake_sqs/actions/delete_message_batch'
require 'fake_sqs/actions/send_message_batch'

module FakeSQS

  InvalidAction = Class.new(ArgumentError)

  class API

    attr_reader :queues

    def initialize(options = {})
      @queues    = options.fetch(:queues)
      @options   = options
    end

    def call(action, *args)
      if FakeSQS::Actions.const_defined?(action)
        FakeSQS::Actions.const_get(action).new(@options).call(*args)
      else
        fail InvalidAction, "Unknown (or not yet implemented) action: #{action}"
      end
    end

    # Fake actions

    def reset
      queues.reset
    end

    def expire
      queues.expire
    end

  end
end
