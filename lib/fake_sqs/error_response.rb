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
      @status ||= statuses.fetch(error.class.name) { 500 }
    end

    def body
      xml = Builder::XmlMarkup.new(:index => 4)
      xml.ErrorResponse do
        xml.Error do
          xml.Type type
          xml.Code error.class.name
          xml.Message error.to_s
          xml.Detail
        end
        xml.RequestId SecureRandom.uuid
      end
    end

    private

    def type
      if status < 500
        "Sender"
      else
        "Receiver"
      end
    end

    def statuses
      YAML.load_file(File.expand_path('../error_responses.yml', __FILE__))
    end

  end
end
