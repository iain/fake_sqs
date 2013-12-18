require 'fake_sqs/api'

class FakeSQS::Actions::TheAction

  def initialize(options)
    @options = options
  end

  def call(params)
    { :options => @options, :params => params }
  end

end

describe FakeSQS::API do

  it "delegates actions to classes" do
    queues = double :queues
    allow(queues).to receive(:transaction).and_yield
    api = FakeSQS::API.new(:queues => queues)

    response = api.call("TheAction", {:foo => "bar"})

    response[:options].should eq :queues => queues
    response[:params].should eq :foo => "bar"
  end

  it "raises InvalidAction for unknown actions" do
    api = FakeSQS::API.new(:queues => [])

    expect {
      api.call("SomethingDifferentAndUnknown", {:foo => "bar"})
    }.to raise_error(FakeSQS::InvalidAction)

  end

  it "resets queues" do
    queues = double :queues
    api = FakeSQS::API.new(:queues => queues)
    queues.should_receive(:reset)
    api.reset
  end

  it "expires messages in queues" do
    queues = double :queues
    api = FakeSQS::API.new(:queues => queues)
    queues.should_receive(:expire)
    api.expire
  end

end
