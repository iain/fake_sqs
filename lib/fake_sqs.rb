require 'fake_sqs/api'
require 'fake_sqs/catch_errors'
require 'fake_sqs/error_response'
require 'fake_sqs/message'
require 'fake_sqs/queue'
require 'fake_sqs/queue_factory'
require 'fake_sqs/queues'
require 'fake_sqs/responder'
require 'fake_sqs/server'
require 'fake_sqs/version'
require 'fake_sqs/memory_database'
require 'fake_sqs/file_database'
require 'fake_sqs/web_interface'

module FakeSQS

  def self.server(options = {})
    Server.new(options)
  end

  def self.api(options = {})
    db = database_for(options.fetch(:database) { ":memory:" })
    API.new(
      server: options.fetch(:server),
      queues: queues(db),
      responder: responder
    )
  end

  def self.queues(database)
    Queues.new(queue_factory: queue_factory, database: database)
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

  def self.database_for(name)
    if name == ":memory:"
      MemoryDatabase.new
    else
      FileDatabase.new(name)
    end
  end

end
