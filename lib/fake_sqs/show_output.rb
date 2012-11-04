module FakeSQS
  class ShowOutput
    def initialize(app)
      @app = app
    end

    def call(env)
      result = @app.call(env)
      puts *result.last
      result
    end
  end
end
