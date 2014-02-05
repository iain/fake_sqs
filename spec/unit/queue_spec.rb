require 'fake_sqs/queue'
require 'fake_sqs/message'

describe FakeSQS::Queue do

  class MessageFactory
    def new(options = {})
      FakeSQS::Message.new({'MessageBody' => 'sample-body'}.merge(options))
    end
  end

  let(:message_factory) { MessageFactory.new }
  subject(:queue) { FakeSQS::Queue.new(:message_factory => message_factory, "QueueName" => "test-queue") }

  describe "#send_message" do

    it "adds a message" do
      queue.should have(0).messages
      send_message
      queue.should have(1).messages
    end

    it "returns the message" do
      message = double.as_null_object
      message_factory.stub(:new).and_return(message)
      send_message.should eq message
    end

    it "uses the message factory" do
      options = { "MessageBody" => "abc" }
      message_factory.should_receive(:new).with(options)
      send_message(options)
    end

  end

  describe "#receive_message" do

    it "gets the message" do
      sent = send_message
      received = receive_message
      received.values.first.should eq sent
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

      (indexes[:first] + indexes[:second]).should eq sample_group

      indexes[:first].should be_within(ten_percent).of(half_sample_group)
      indexes[:second].should be_within(ten_percent).of(half_sample_group)
    end

    it "cannot get received messages" do
      sample_group = 1_000

      sample_group.times do
        sent_first  = send_message
        sent_second = send_message
        received_first  = receive_message.values.first

        if received_first == sent_first
          receive_message.values.first.should eq sent_second
        else
          receive_message.values.first.should eq sent_first
        end
        reset_queue
      end
    end

    it "keeps track of sent messages" do

      send_message

      queue.should have(0).messages_in_flight
      queue.attributes["ApproximateNumberOfMessagesNotVisible"].should eq 0
      queue.attributes["ApproximateNumberOfMessages"].should eq 1

      receive_message

      queue.should have(1).messages_in_flight
      queue.attributes["ApproximateNumberOfMessagesNotVisible"].should eq 1
      queue.attributes["ApproximateNumberOfMessages"].should eq 0
    end

    it "gets multiple message" do
      sent_first  = send_message
      sent_second = send_message
      messages = receive_message("MaxNumberOfMessages" => "2")
      messages.size.should eq 2
      messages.values.should match_array [ sent_first, sent_second ]
    end

    it "won't accept more than 10 message" do
      expect {
        receive_message("MaxNumberOfMessages" => "11")
      }.to raise_error(FakeSQS::ReadCountOutOfRange, "11")
    end

    it "won't error on empty queues" do
      receive_message.should eq({})
    end

  end

  describe "#delete_message" do

    it "deletes by the receipt" do
      send_message
      receipt = receive_message.keys.first

      queue.should have(1).messages_in_flight
      queue.delete_message(receipt)
      queue.should have(0).messages_in_flight
      queue.should have(0).messages
    end

    it "won't raise if the receipt is unknown" do
      queue.delete_message("abc")
    end

  end

  describe "#add_queue_attributes" do

    it "adds to it's queue attributes" do
      queue.add_queue_attributes("foo" => "bar")
      queue.attributes.should eq(
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
