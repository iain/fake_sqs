require 'support/aws'

describe "Actions for Messages", :acceptance do

  before do
    sqs.queues.create("test")
  end

  let(:sqs) { AWS::SQS.new }
  let(:queue) { sqs.queues.named("test") }

  specify "SendMessage" do
    msg = "this is my message"
    result = queue.send_message(msg)
    result.md5.should eq Digest::MD5.hexdigest(msg)
  end

  specify "ReceiveMessage" do
    body = "test 123"
    queue.send_message(body)
    message = queue.receive_message
    message.body.should eq body
  end

  specify "DeleteMessage" do
    queue.send_message("test")

    message1 = queue.receive_message
    message1.delete

    let_messages_in_flight_expire

    message2 = queue.receive_message
    message2.should be_nil
  end

  specify "DeleteMessageBatch" do
    queue.send_message("test1")
    queue.send_message("test2")

    message1 = queue.receive_message
    message2 = queue.receive_message
    queue.batch_delete(message1, message2)

    let_messages_in_flight_expire

    message3 = queue.receive_message
    message3.should be_nil
  end

  specify "SendMessageBatch" do
    bodies = %w(a b c)
    queue.batch_send(*bodies)

    messages = queue.receive_message(:limit => 10)
    messages.map(&:body).should match_array bodies
  end

end
