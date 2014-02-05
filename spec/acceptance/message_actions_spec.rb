require "spec_helper"

describe "Actions for Messages", :sqs do

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

  specify "set message timeout to 0" do
    body = 'some-sample-message'
    queue.send_message(body)
    message = queue.receive_message
    message.body.should == body
    message.visibility_timeout = 0

    same_message = queue.receive_message
    same_message.body.should == body
  end

  specify 'set message timeout and wait for message to come' do

    body = 'some-sample-message'
    queue.send_message(body)
    message = queue.receive_message
    message.body.should == body
    message.visibility_timeout = 3

    nothing = queue.receive_message
    nothing.should be_nil

    sleep(10)

    same_message = queue.receive_message
    same_message.body.should == body
  end

  specify 'should fail if trying to update the visibility_timeout for a message that is not in flight' do
    body = 'some-sample-message'
    queue.send_message(body)
    message = queue.receive_message
    message.body.should == body
    message.visibility_timeout = 0

    expect do
      message.visibility_timeout = 30
    end.to raise_error(AWS::SQS::Errors::MessageNotInflight)
  end

  def let_messages_in_flight_expire
    $fake_sqs.expire
  end

end
