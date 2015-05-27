require 'fake_sqs/catch_errors'

RSpec.describe FakeSQS::CatchErrors do

  let(:app) { double :app }
  let(:error_response) { double :error_response, :status => 500, :body => "X" }
  let(:response) { double :response, :new => error_response }
  subject(:catch_errors) { FakeSQS::CatchErrors.new(app, response: response) }

  context "when the app behaves normally" do

    let(:normal_response) { double :normal_response }
    before { allow(app).to receive(:call).and_return(normal_response) }

    it "doesn't modify normal responses" do
      expect(catch_errors.call({})).to eq normal_response
    end

  end

  context "when the app raises an exception" do

    let(:error) { RuntimeError.new("it went wrong") }
    before { allow(app).to receive(:call).and_raise(error) }

    it "cathes and processes errors" do
      expect(response).to receive(:new).with(error)
      catch_errors.call({})
    end

    it "sets the status determined by the error response" do
      allow(error_response).to receive(:status).and_return(123)
      expect(catch_errors.call({}).fetch(0)).to eq 123
    end

    it "set the body determined by the error response" do
      allow(error_response).to receive(:body).and_return("foobar")
      expect(catch_errors.call({}).fetch(2)).to eq ["foobar"]
    end

  end

end
