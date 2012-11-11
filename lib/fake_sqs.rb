require 'fake_sqs/catch_errors'
require 'fake_sqs/error_response'
require 'fake_sqs/message'
require 'fake_sqs/queue'
require 'fake_sqs/queue_factory'
require 'fake_sqs/queues'
require 'fake_sqs/responder'
require 'fake_sqs/server'
require 'fake_sqs/version'

module FakeSQS

  def self.server(options = {})
    Server.new(options.merge(queues: queues, responder: responder))
  end

  def self.queues
    Queues.new(queue_factory: queue_factory)
  end

  def self.responder
    Responder.new
  end

  def self.queue_factory
    QueueFactory.new(message_factory: message_factory, queue: queue)
  end

  def self.message_factory
    Message
  end

  def self.queue
    Queue
  end

end
