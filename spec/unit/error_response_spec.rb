require 'fake_sqs/error_response'
require 'active_support/core_ext/hash'
require 'verbose_hash_fetch'

RSpec.describe FakeSQS::ErrorResponse do

  module FakeSQS
    MissingCredentials = Class.new(RuntimeError)
  end
  ErrorUnknownToSQS = Class.new(RuntimeError)

  describe "#status" do

    it "picks the right error status" do
      error = FakeSQS::MissingCredentials.new("message")
      response = FakeSQS::ErrorResponse.new(error)
      expect(response.status).to eq 401
    end

    it "uses 400 as default status" do
      error = ErrorUnknownToSQS.new("message")
      response = FakeSQS::ErrorResponse.new(error)
      expect(response.status).to eq 500
    end

  end

  describe "#body" do

    let(:error) { FakeSQS::MissingCredentials.new("the message") }
    let(:response) { FakeSQS::ErrorResponse.new(error) }
    let(:data) { Hash.from_xml(response.body) }

    it "uses the error class name as error code" do
      expect(data.fetch("ErrorResponse").fetch("Error").fetch("Code")).to eq "MissingCredentials"
    end

    it "uses InternalError as code for unknown errors" do
      error = ErrorUnknownToSQS.new("the message")
      response = FakeSQS::ErrorResponse.new(error)
      data = Hash.from_xml(response.body)
      expect(data.fetch("ErrorResponse").fetch("Error").fetch("Code")).to eq "InternalError"
    end

    it "uses the to_s of the error as message" do
      expect(data.fetch("ErrorResponse").fetch("Error").fetch("Message")).to eq "the message"
    end

    it "has a request id" do
      expect(data.fetch("ErrorResponse").fetch("RequestId").size).to eq 36
    end

    it "uses Sender as type for 4xx responses" do
      allow(response).to receive(:status).and_return(400)
      expect(data.fetch("ErrorResponse").fetch("Error").fetch("Type")).to eq "Sender"
    end

    it "uses Receiver as type for 5xx responses" do
      allow(response).to receive(:status).and_return(500)
      expect(data.fetch("ErrorResponse").fetch("Error").fetch("Type")).to eq "Receiver"
    end

  end

end
