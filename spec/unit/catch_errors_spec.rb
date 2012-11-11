require 'fake_sqs/catch_errors'

describe FakeSQS::CatchErrors do

  let(:app) { double :app }
  let(:error_response) { double :error_response, :status => 500, :body => "X" }
  let(:response) { double :response, :new => error_response }
  subject(:catch_errors) { FakeSQS::CatchErrors.new(app, response: response) }

  context "when the app behaves normally" do

    let(:normal_response) { double :normal_response }
    before { app.stub(:call => normal_response) }

    it "doesn't modify normal responses" do
      catch_errors.call({}).should eq normal_response
    end

  end

  context "when the app raises an exception" do

    let(:error) { RuntimeError.new("it went wrong") }
    before { app.stub(:call).and_raise(error) }

    it "cathes and processes errors" do
      response.should_receive(:new).with(error)
      catch_errors.call({})
    end

    it "sets the status determined by the error response" do
      error_response.stub(:status => 123)
      catch_errors.call({}).fetch(0).should eq 123
    end

    it "set the body determined by the error response" do
      error_response.stub(:body => "foobar")
      catch_errors.call({}).fetch(2).should eq ["foobar"]
    end

  end

end
