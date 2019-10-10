require 'securerandom'
require 'digest/sha1'

module FakeSQS
  class Message

    attr_reader :body, :id, :md5, :delay_seconds, :approximate_receive_count,
    :sender_id, :approximate_first_receive_timestamp, :sent_timestamp, :message_attributes
    attr_accessor :visibility_timeout

    def initialize(options = {})
      @body = options.fetch("MessageBody")
      @id = options.fetch("Id") { SecureRandom.uuid }
      @md5 = options.fetch("MD5") { Digest::MD5.hexdigest(@body) }
      @message_attributes = extract_attributes(options)

      @sender_id = options.fetch("SenderId") { SecureRandom.uuid.delete('-').upcase[0...21] }
      @approximate_receive_count = 0
      @sent_timestamp = Time.now.to_i * 1000
      @delay_seconds = options.fetch("DelaySeconds", 0).to_i
    end

    def expire!
      self.visibility_timeout = nil
    end

    def receive!
      @approximate_first_receive_timestamp ||= Time.now.to_i * 1000
      @approximate_receive_count += 1
    end

    def expired?( limit = Time.now )
      self.visibility_timeout.nil? || self.visibility_timeout < limit
    end

    def expire_at(seconds)
      self.visibility_timeout = Time.now + seconds
    end

    def published?
      if self.delay_seconds && self.delay_seconds > 0
        elapsed_seconds = Time.now.to_i - (self.sent_timestamp.to_i / 1000)
        elapsed_seconds >= self.delay_seconds
      else
        true
      end
    end

    def attributes
      {
        "SenderId" => sender_id,
        "ApproximateFirstReceiveTimestamp" => approximate_first_receive_timestamp,
        "ApproximateReceiveCount"=> approximate_receive_count,
        "SentTimestamp"=> sent_timestamp
      }
    end

    def receipt
      Digest::SHA1.hexdigest self.id
    end
    def message_attributes_md5
      sorted_attributes = @message_attributes.sort { |a,b| a["Name"] <=> b["Name"] }

      buffer = sorted_attributes.each_with_object([]) do |attribute, buffer|
        add_string_to_buffer(attribute["Name"], buffer)
        add_string_to_buffer(attribute["Value.DataType"], buffer)

        if (attribute["Value.StringValue"])
          buffer << 1
          add_string_to_buffer(attribute["Value.StringValue"], buffer)
        elsif (attribute["Value.BinaryValue"])
          buffer << 2
          add_binary_to_buffer(attribute["Value.BinaryValue"], buffer)
        end
      end
      Digest::MD5.hexdigest(buffer.pack("C*"))
    end

    def add_string_to_buffer(string, buffer)
      string_bytes = string.force_encoding('UTF-8').bytes.to_a
      buffer.concat [string_bytes.size].pack("N").bytes.to_a
      buffer.concat string_bytes
    end

    def add_binary_to_buffer(binary, buffer)
      binary_bytes = binary.unpack("m*")[0].bytes.to_a
      buffer.concat [binary_bytes.size].pack("N").bytes.to_a
      buffer.concat binary_bytes
    end

    private
    def extract_attributes(options)
      attributes = []
      options.each {|key, value|
        if /MessageAttribute\.(?<attr_index>\d+)\.(?<attr_name>.*)/ =~ key
          index = attr_index.to_i - 1
          attributes[index] = Hash.new unless attributes[index]
          attributes[index][attr_name] = value
        end
      }
      attributes
    end

  end
end
