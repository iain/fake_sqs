require 'securerandom'

module FakeSQS
  class Message

    attr_reader :body, :id, :md5

    def initialize(options = {})
      @body = options.fetch("MessageBody")
      @id = options.fetch("Id") { SecureRandom.uuid }
      @md5 = options.fetch("MD5") { Digest::MD5.hexdigest(@body) }
    end

    def attributes
      {
        "MessageBody" => body,
        "Id" => id,
        "MD5" => md5,
      }
    end

  end
end
