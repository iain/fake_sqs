require 'fake_sqs/error_response'
require 'active_support/core_ext/hash'
require 'verbose_hash_fetch'

describe FakeSQS::ErrorResponse do

  module FakeSQS
    MissingCredentials = Class.new(RuntimeError)
  end
  ErrorUnknownToSQS = Class.new(RuntimeError)

  describe "#status" do

    it "picks the right error status" do
      error = FakeSQS::MissingCredentials.new("message")
      response = FakeSQS::ErrorResponse.new(error)
      response.status.should eq 401
    end

    it "uses 400 as default status" do
      error = ErrorUnknownToSQS.new("message")
      response = FakeSQS::ErrorResponse.new(error)
      response.status.should eq 500
    end

  end

  describe "#body" do

    let(:error) { FakeSQS::MissingCredentials.new("the message") }
    let(:response) { FakeSQS::ErrorResponse.new(error) }
    let(:data) { Hash.from_xml(response.body) }

    it "uses the error class name as error code" do
      data.fetch("ErrorResponse").fetch("Error").fetch("Code").should eq "MissingCredentials"
    end

    it "uses InternalError as code for unknown errors" do
      error = ErrorUnknownToSQS.new("the message")
      response = FakeSQS::ErrorResponse.new(error)
      data = Hash.from_xml(response.body)
      data.fetch("ErrorResponse").fetch("Error").fetch("Code").should eq "InternalError"
    end

    it "uses the to_s of the error as message" do
      data.fetch("ErrorResponse").fetch("Error").fetch("Message").should eq "the message"
    end

    it "has a request id" do
      data.fetch("ErrorResponse").fetch("RequestId").should have(36).characters
    end

    it "uses Sender as type for 4xx responses" do
      response.stub(:status => 400)
      data.fetch("ErrorResponse").fetch("Error").fetch("Type").should eq "Sender"
    end

    it "uses Receiver as type for 5xx responses" do
      response.stub(:status => 500)
      data.fetch("ErrorResponse").fetch("Error").fetch("Type").should eq "Receiver"
    end

  end

end
