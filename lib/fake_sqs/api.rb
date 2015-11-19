require 'fake_sqs/actions/change_message_visibility'
require 'fake_sqs/actions/create_queue'
require 'fake_sqs/actions/delete_queue'
require 'fake_sqs/actions/list_queues'
require 'fake_sqs/actions/get_queue_url'
require 'fake_sqs/actions/send_message'
require 'fake_sqs/actions/receive_message'
require 'fake_sqs/actions/delete_message'
require 'fake_sqs/actions/delete_message_batch'
require 'fake_sqs/actions/purge_queue'
require 'fake_sqs/actions/send_message_batch'
require 'fake_sqs/actions/get_queue_attributes'
require 'fake_sqs/actions/set_queue_attributes'

module FakeSQS

  InvalidAction = Class.new(ArgumentError)

  class API

    attr_reader :queues, :options

    def initialize(options = {})
      @queues    = options.fetch(:queues)
      @options   = options
      @run_timer = true
      @timer     = Thread.new do
        while @run_timer
          queues.timeout_messages!
          sleep(5)
        end
      end
    end

    def call(action, request, *args)
      if FakeSQS::Actions.const_defined?(action)
        action = FakeSQS::Actions.const_get(action).new(options.merge(request: request))
        queues.transaction do
          action.call(*args)
        end
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

    def stop
      @run_timer = false
    end

  end
end
