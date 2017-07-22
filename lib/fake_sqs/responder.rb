require 'builder'
require 'securerandom'

module FakeSQS
  class Responder

    def call(name, &block)
      xml = Builder::XmlMarkup.new
      xml.tag! "#{name}Response" do
        if block
          xml.tag! "#{name}Result" do
            yield xml
          end
        end
        xml.ResponseMetadata do
          xml.RequestId SecureRandom.uuid
        end
      end
    end

  end
end
