require 'fake_sqs/queue'
require 'fake_sqs/message'

RSpec.describe FakeSQS::Queue do

  class MessageFactory
    def new(options = {})
      FakeSQS::Message.new({'MessageBody' => 'sample-body'}.merge(options))
    end
  end

  let(:message_factory) { MessageFactory.new }
  subject(:queue) { FakeSQS::Queue.new(:message_factory => message_factory, "QueueName" => "test-queue") }

  describe "#send_message" do

    it "adds a message" do
      expect(queue.messages.size).to eq 0
      send_message
      expect(queue.messages.size).to eq 1
    end

    it "returns the message" do
      message = double.as_null_object
      allow(message_factory).to receive(:new).and_return(message)
      expect(send_message).to eq message
    end

    it "uses the message factory" do
      options = { "MessageBody" => "abc" }
      expect(message_factory).to receive(:new).with(options)
      send_message(options)
    end

  end

  describe "#receive_message" do

    it "gets the message" do
      sent = send_message
      received = receive_message
      expect(received.values.first).to eq sent
    end

    it "gets you a random message" do
      indexes = { :first => 0, :second => 0 }
      sample_group = 1_000
      half_sample_group = sample_group / 2
      ten_percent = half_sample_group / 0.1

      sample_group.times do
        sent_first     = send_message
        _    = send_message
        message = receive_message.values.first
        if message == sent_first
          indexes[:first] += 1
        else
          indexes[:second] += 1
        end
        reset_queue
      end

      expect(indexes[:first] + indexes[:second]).to eq sample_group

      expect(indexes[:first]).to be_within(ten_percent).of(half_sample_group)
      expect(indexes[:second]).to be_within(ten_percent).of(half_sample_group)
    end

    it "cannot get received messages" do
      sample_group = 1_000

      sample_group.times do
        sent_first  = send_message
        sent_second = send_message
        received_first  = receive_message.values.first

        if received_first == sent_first
          expect(receive_message.values.first).to eq sent_second
        else
          expect(receive_message.values.first).to eq sent_first
        end
        reset_queue
      end
    end

    it "keeps track of sent messages" do

      send_message

      expect(queue.messages_in_flight.size).to eq 0
      expect(queue.attributes["ApproximateNumberOfMessagesNotVisible"]).to eq 0
      expect(queue.attributes["ApproximateNumberOfMessages"]).to eq 1

      receive_message

      expect(queue.messages_in_flight.size).to eq 1
      expect(queue.attributes["ApproximateNumberOfMessagesNotVisible"]).to eq 1
      expect(queue.attributes["ApproximateNumberOfMessages"]).to eq 0
    end

    it "gets multiple message" do
      sent_first  = send_message
      sent_second = send_message
      messages = receive_message("MaxNumberOfMessages" => "2")
      expect(messages.size).to eq 2
      expect(messages.values).to match_array [ sent_first, sent_second ]
    end

    it "won't accept more than 10 message" do
      expect {
        receive_message("MaxNumberOfMessages" => "11")
      }.to raise_error(FakeSQS::ReadCountOutOfRange, "11")
    end

    it "won't error on empty queues" do
      expect(receive_message).to eq({})
    end

  end

  describe "#delete_message" do

    it "deletes by the receipt" do
      send_message
      receipt = receive_message.keys.first

      expect(queue.messages_in_flight.size).to eq 1
      queue.delete_message(receipt)
      expect(queue.messages_in_flight.size).to eq 0
      expect(queue.messages.size).to eq 0
    end

    it "won't raise if the receipt is unknown" do
      queue.delete_message("abc")
    end

  end

  describe "#add_queue_attributes" do

    it "adds to it's queue attributes" do
      queue.add_queue_attributes("foo" => "bar")
      expect(queue.attributes).to eq(
        "foo"                                   => "bar",
        "QueueArn"                              => queue.arn,
        "ApproximateNumberOfMessages"           => 0,
        "ApproximateNumberOfMessagesNotVisible" => 0
      )
    end

  end

  def send_message(options = {})
    queue.send_message(options)
  end

  def receive_message(options = {})
    queue.receive_message(options)
  end

  def reset_queue
    queue.reset
  end

end
