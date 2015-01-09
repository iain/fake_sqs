require 'fake_sqs/api'
require 'fake_sqs/catch_errors'
require 'fake_sqs/collection_view'
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
require 'fake_sqs/extended_hash'

module FakeSQS

  def self.to_rack(options)

    require 'fake_sqs/web_interface'
    app = FakeSQS::WebInterface

    if (log = options[:log])
      file = File.new(log, "a+")
      file.sync = true
      app.use Rack::CommonLogger, file
      app.set :log_file, file
      app.enable :logging
    end

    if options[:verbose]
      require 'fake_sqs/show_output'
      app.use FakeSQS::ShowOutput
      app.enable :logging
    end

    if options[:daemonize]
      require 'fake_sqs/daemonize'
      Daemonize.new(options).call
    end

    app.set :port, options[:port] if options[:port]
    app.set :bind, options[:host] if options[:host]
    app.set :server, options[:server] if options[:server]
    server = FakeSQS.server(port: options[:port], host: options[:host])
    app.set :api, FakeSQS.api(server: server, database: options[:database])
    app
  end

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
