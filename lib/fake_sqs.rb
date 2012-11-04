require 'fake_sqs/version'
require 'fake_sqs/server'
require 'fake_sqs/queues'
require 'fake_sqs/responder'
require 'fake_sqs/queue'
require 'fake_sqs/queue_factory'
require 'fake_sqs/message'

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
    QueueFactory.new(message_factory: message_factory)
  end

  def self.message_factory
    Message
  end

end
