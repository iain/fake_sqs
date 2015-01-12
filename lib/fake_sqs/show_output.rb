require 'rack'
require 'rack/request'
require 'yaml'

module FakeSQS
  class ShowOutput

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      result = @app.call(env)
      puts request.params.to_yaml
      puts
      puts *result.last
      result
    end

  end
end
