require 'sinatra/base'

module FakeSQS
  class Helper

    def queue_from_url(queue_url)
      uri = URI.parse(queue_url)
      return uri.path.tr('/', '')
    end

  end
end
