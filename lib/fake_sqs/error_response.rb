require 'yaml'
require 'builder'
require 'securerandom'

module FakeSQS
  class ErrorResponse

    attr_reader :error

    def initialize(error)
      @error = error
    end

    def status
      @status ||= statuses.fetch(code)
    end

    def body
      xml = Builder::XmlMarkup.new(:index => 4)
      xml.ErrorResponse do
        xml.Error do
          xml.Type type
          xml.Code code
          xml.Message error.to_s
          xml.Detail
        end
        xml.RequestId SecureRandom.uuid
      end
    end

    private

    def code
      code = error.class.name.sub(/^FakeSQS::/, '')
      if statuses.has_key?(code)
        code
      else
        "InternalError"
      end
    end

    def type
      if status < 500
        "Sender"
      else
        "Receiver"
      end
    end

    def statuses
      @statuses ||= YAML.load_file(File.expand_path('../error_responses.yml', __FILE__))
    end

  end
end
