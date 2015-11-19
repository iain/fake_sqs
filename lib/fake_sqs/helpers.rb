module FakeSQS
  module Helpers
    def self.queue_url(request, queue_name)
      "http://#{request.env["HTTP_HOST"]}/#{queue_name}"
    end
  end
end