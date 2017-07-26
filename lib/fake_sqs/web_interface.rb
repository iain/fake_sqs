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
      if params['QueueUrl']
        uri = URI.parse(params['QueueUrl'])
        queue_name = uri.path.tr('/', '')
        return settings.api.call(action, request, queue_name, params) unless queue_name.empty?
      end

      settings.api.call(action, request, params)
    end

    handle "/:queue_name", [:get, :post] do |queue_name|
      settings.api.call(action, request, queue_name, params)
    end
  end
end
