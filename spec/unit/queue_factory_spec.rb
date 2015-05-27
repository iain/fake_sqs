require 'fake_sqs/queue_factory'

RSpec.describe FakeSQS::QueueFactory do

  it "builds queues with a message factory" do
    message_factory = double :message_factory
    queue = double :queue
    queue_factory = FakeSQS::QueueFactory.new(message_factory: message_factory, queue: queue)
    expect(queue).to receive(:new).with(message_factory: message_factory, name: "Foo")
    queue_factory.new(name: "Foo")
  end

end
