require 'securerandom'

module FakeSQS
  class Message

    attr_reader :body, :id, :md5, :message_attributes
    attr_accessor :visibility_timeout

    def initialize(options = {})
      @body = options.fetch("MessageBody")
      @id = options.fetch("Id") { SecureRandom.uuid }
      @md5 = options.fetch("MD5") { Digest::MD5.hexdigest(@body) }
      @message_attributes = extract_attributes(options)
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
      }
    end

    def message_attributes_md5
        sorted_attributes = @message_attributes.sort { |a,b| a["Name"] <=> b["Name"] }

        buffer = []

        sorted_attributes.each do |attribute|

            add_string_to_buffer(buffer, attribute["Name"])
            add_string_to_buffer(buffer, attribute["DataType"])

            if (attribute["StringValue"])
                buffer << 1
                add_string_to_buffer(buffer, attribute["StringValue"])
            else
                buffer << 2
                add_binary_to_buffer(buffer, attribute["BinaryValue"])
            end
        end

        Digest::MD5.hexdigest(buffer.pack("C*"))
    end

    def add_string_to_buffer(buffer, string)
        string_bytes = string.force_encoding('UTF-8').bytes

        buffer.concat [string_bytes.length].pack("N").bytes
        buffer.concat string_bytes

        buffer
    end

    def add_binary_to_buffer(buffer, binary)
        bytes = binary.unpack("m*")[0].bytes

        buffer.concat [bytes.length].pack("N").bytes
        buffer.concat bytes

        buffer
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
