require 'securerandom'

module FakeSQS
  class Message

    attr_reader :body

    def initialize(options = {})
      @body = options.fetch("MessageBody")
    end

    def id
      @id ||= SecureRandom.uuid
    end

    def md5
      @md5 ||= Digest::MD5.hexdigest(body)
    end

  end
end
