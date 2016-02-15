require 'securerandom'

module FakeSQS
  class Message

    attr_reader :body, :id, :md5, :delay_seconds, :created_at
    attr_accessor :visibility_timeout

    def initialize(options = {})
      @body = options.fetch("MessageBody")
      @id = options.fetch("Id") { SecureRandom.uuid }
      @md5 = options.fetch("MD5") { Digest::MD5.hexdigest(@body) }
      @delay_seconds = options.fetch("DelaySeconds", 0).to_i
      @created_at = Time.now
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

    def published?
      if self.delay_seconds && self.delay_seconds > 0
        elapsed_seconds = Time.now.to_i - self.created_at.to_i
        elapsed_seconds >= self.delay_seconds
      else
        true
      end
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
