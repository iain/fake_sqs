require 'fake_sqs/actions/change_message_visibility'
require 'fake_sqs/actions/change_message_visibility_batch'
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
require 'fake_sqs/actions/list_dead_letter_source_queues'

module FakeSQS

  InvalidAction = Class.new(ArgumentError)

  class API

    attr_reader :queues, :options

    def initialize(options = {})
      @queues    = options.fetch(:queues)
      @options   = options
      @halt      = false
      @timer     = Thread.new do
        until @halt
          queues.timeout_messages!
          sleep(0.1)
        end
      end
    end

    def call(action, request, *args)
      if FakeSQS::Actions.const_defined?(action)
        action = FakeSQS::Actions.const_get(action).new(options.merge({:request => request}))
        if action.respond_to?(:satisfied?)
          result = nil
          until @halt
            result = attempt_once(action, *args)
            break if action.satisfied?
            sleep(0.1)
          end
          result
        else
          attempt_once(action, *args)
        end
      else
        fail InvalidAction, "Unknown (or not yet implemented) action: #{action}"
      end
    end

    def attempt_once(action, *args)
      queues.transaction do
        action.call(*args)
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
      @halt = true
    end

  end
end
