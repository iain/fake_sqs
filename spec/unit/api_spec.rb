require 'fake_sqs/api'

class FakeSQS::Actions::TheAction

  def initialize(options)
    @options = options
  end

  def call(params)
    { :options => @options, :params => params }
  end

end

RSpec.describe FakeSQS::API do

  it "delegates actions to classes" do
    queues = double :queues
    allow(queues).to receive(:transaction).and_yield
    api = FakeSQS::API.new(:queues => queues)

    response = api.call("TheAction", "foo", {:foo => "bar"})

    expect(response[:options]).to eq :queues => queues, :request => "foo"
    expect(response[:params]).to eq :foo => "bar"
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
    expect(queues).to receive(:reset)
    api.reset
  end

  it "expires messages in queues" do
    queues = double :queues
    api = FakeSQS::API.new(:queues => queues)
    expect(queues).to receive(:expire)
    api.expire
  end

end
