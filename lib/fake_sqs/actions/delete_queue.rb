module FakeSQS
  module Actions
    class DeleteQueue

      def initialize(request, options = {})
        @request   = request
        @queues    = options.fetch(:queues)
        @responder = options.fetch(:responder)
      end

      def call(name, params)
        @queues.delete(name, params)
        @responder.call :DeleteQueue
      end

    end
  end
end
