require 'fake_sqs/queues'
require 'fake_sqs/memory_database'

RSpec.describe FakeSQS::Queues do

  let(:fake_database) { FakeSQS::MemoryDatabase.new }
  let(:queue_factory) { double :queue_factory, :new => double }
  subject(:queues) { FakeSQS::Queues.new(queue_factory: queue_factory, database: fake_database) }

  describe "#create" do

    it "creates new queues" do
      expect(queues.list.size).to eq 0
      create_queue("test")
      expect(queues.list.size).to eq 1
    end

    it "uses the queue factory" do
      params = double :params
      expect(queue_factory).to receive(:new).with(params)
      create_queue("test", params)
    end

    it "returns the queue" do
      queue = double
      allow(queue_factory).to receive(:new).and_return(queue)
      expect(create_queue("test")).to eq queue
    end

    it "returns existing queue if the queue exists" do
      queue = create_queue("test")
      expect(create_queue("test")).to eq(queue)
    end

  end

  describe "#delete" do

    it "deletes an existing queue" do
      create_queue("test")
      expect(queues.list.size).to eq 1
      queues.delete("test")
      expect(queues.list.size).to eq 0
    end

    it "cannot delete an non-existing queue" do
      expect {
        queues.delete("test")
      }.to raise_error(FakeSQS::NonExistentQueue, "test")
    end

  end

  describe "#list" do

    it "returns all the queues" do
      queue1 = create_queue("test-1")
      queue2 = create_queue("test-2")
      expect(queues.list).to eq [ queue1, queue2 ]
    end

    it "can be filtered by prefix" do
      queue1 = create_queue("test-1")
      queue2 = create_queue("test-2")
      _ = create_queue("other-3")
      expect(queues.list("QueueNamePrefix" => "test")).to eq [ queue1, queue2 ]
    end

  end

  describe "#get" do

    it "finds the queue by name" do
      queue = create_queue("test")
      expect(queues.get("test")).to eq queue
    end

    it "cannot get the queue if it doesn't exist" do
      expect {
        queues.get("test")
      }.to raise_error(FakeSQS::NonExistentQueue, "test")
    end

  end

  describe "#reset" do

    it "clears all queues" do
      create_queue("foo")
      create_queue("bar")
      expect(queues.list.size).to eq 2
      queues.reset
      expect(queues.list.size).to eq 0
    end

  end

  def create_queue(name, options = {})
    queues.create(name, options)
  end

end
