require 'fake_sqs/api'

class FakeSQS::Actions::ImmediateAction

  def initialize(options)
    @options = options
  end

  def call(params)
    { :options => @options, :params => params }
  end

end

class FakeSQS::Actions::PollingAction

  def initialize(options)
    @options = options
    @call_count = 0
  end

  def call(params)
    @call_count += 1
  end

  def satisfied?
    @call_count >= 3
  end
end

RSpec.describe FakeSQS::API do

  it "delegates actions to classes" do
    queues = double :queues
    allow(queues).to receive(:transaction).and_yield
    api = FakeSQS::API.new(:queues => queues)

    response = api.call("ImmediateAction", {}, {:foo => "bar"})

    expect(response[:options]).to eq :queues => queues, :request => {}
    expect(response[:params]).to eq :foo => "bar"
  end

  it "attempts a polling action until it's satisfied" do
    queues = double :queues
    allow(queues).to receive(:transaction).and_yield
    api = FakeSQS::API.new(:queues => queues)

    call_count = api.call("PollingAction", {}, {})
    expect(call_count).to eq 3
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
