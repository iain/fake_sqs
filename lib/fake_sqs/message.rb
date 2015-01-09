require 'securerandom'

module FakeSQS
  class Message

    attr_reader :body, :id, :md5, :message_attributes
    attr_accessor :visibility_timeout

    def initialize(options = {})
      @body = options.fetch("MessageBody")
      @id = options.fetch("Id") { SecureRandom.uuid }
      @md5 = options.fetch("MD5") { Digest::MD5.hexdigest(@body) }
      @message_attributes = options.fetch("MessageAttribute", [])
    end

    def expire!
      self.visibility_timeout = nil
    end

    def expired?( limit = Time.now )
      self.visibility_timeout.nil? || self.visibility_timeout < limit
    end

    def expire_at(seconds)
      self.visibility_timeout = Time.now + seconds
    end

    def attributes
      {
        "MessageBody" => body,
        "Id" => id,
        "MD5" => md5,
        "MessageAttribute" => message_attributes
      }
    end

  end
end
