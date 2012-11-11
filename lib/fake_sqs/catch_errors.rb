require 'securerandom'

module FakeSQS
  class CatchErrors

    def initialize(app, options = {})
      @app = app
      @response = options.fetch(:response)
    end

    def call(env)
      @app.call(env)
    rescue => error
      response = @response.new(error)
      [ response.status, {}, [ response.body ] ]
    end

  end
end
