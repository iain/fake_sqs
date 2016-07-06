require 'sinatra/base'
require 'fake_sqs/catch_errors'
require 'fake_sqs/error_response'

module FakeSQS
  class WebInterface < Sinatra::Base

    def self.handle(path, verbs, &block)
      verbs.each do |verb|
        send(verb, path, &block)
      end
    end

    configure do
      use FakeSQS::CatchErrors, response: ErrorResponse
    end

    helpers do
      def action
        params.fetch("Action")
      end
    end

    get "/ping" do
      200
    end

    delete "/" do
      settings.api.reset
      200
    end

    put "/" do
      settings.api.expire
      200
    end

    handle "/", [:get, :post] do
      params['logger'] = logger
      if params['QueueUrl']
        queue = URI.parse(params['QueueUrl']).path.gsub(/\//, '')
        return settings.api.call(action, request, queue, params) unless queue.empty?
      end

      settings.api.call(action, request, params)
    end

    handle "/:queue", [:get, :post] do |queue|
      settings.api.call(action, request, queue, params)
    end
  end
end
