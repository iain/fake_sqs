require "integration_spec_helper"
require "securerandom"

RSpec.describe "Actions for Messages", :sqs do

  QUEUE_NAME = "test"

  before do
    sqs.config.endpoint = $fake_sqs.uri
    sqs.create_queue(queue_name: QUEUE_NAME)
  end

  let(:sqs) { Aws::SQS::Client.new }
  let(:queue_url) { sqs.get_queue_url(queue_name: QUEUE_NAME).queue_url }

  specify "SendMessage" do
    msg = "this is my message"

    result = sqs.send_message(
      queue_url: queue_url,
      message_body: msg,
    )

    expect(result.md5_of_message_body).to eq Digest::MD5.hexdigest(msg)
    expect(result.message_id.size).to eq 36
  end

  specify "ReceiveMessage" do
    body = "test 123"

    sqs.send_message(
      queue_url: queue_url,
      message_body: body
    )

    response = sqs.receive_message(
      queue_url: queue_url
    )

    expect(response.messages.size).to eq 1
    expect(response.messages.first.body).to eq body
  end

  specify "ReceiveMessage with attribute_names parameters" do
    body = "test 123"

    sqs.send_message(
      queue_url: queue_url,
      message_body: body
    )

    sent_time = Time.now.to_i * 1000

    response = sqs.receive_message(
      queue_url: queue_url,
      attribute_names: ["All"]
    )

    received_time = Time.now.to_i * 1000

    expect(response.messages.first.attributes.reject{|k,v| k == "SenderId"}).to eq({
      "SentTimestamp" => sent_time.to_s,
      "ApproximateReceiveCount" => "1",
      "ApproximateFirstReceiveTimestamp" => received_time.to_s
    })
    expect(response.messages.first.attributes["SenderId"]).to be_kind_of(String)
    expire_message(response.messages.first)

    response = sqs.receive_message(
      queue_url: queue_url
    )
    expect(response.messages.first.attributes).to eq({})
    expire_message(response.messages.first)

    response = sqs.receive_message(
      queue_url: queue_url,
      attribute_names: ["SentTimestamp", "ApproximateReceiveCount", "ApproximateFirstReceiveTimestamp"]
    )
    expect(response.messages.first.attributes).to eq({
      "SentTimestamp" => sent_time.to_s,
      "ApproximateReceiveCount" => "3",
      "ApproximateFirstReceiveTimestamp" => received_time.to_s
    })
  end

  describe "ReceiveMessage long polling" do
    LONG_POLLING_QUEUE_NAME = 'test-long-polling'

    before do
      sqs.create_queue(
        queue_name: LONG_POLLING_QUEUE_NAME,
      )
      sqs.set_queue_attributes(
        queue_url: long_polling_queue_url,
        attributes: {
          "ReceiveMessageWaitTimeSeconds" => "1"
        }
      )
    end

    let(:long_polling_queue_url) { sqs.get_queue_url(queue_name: LONG_POLLING_QUEUE_NAME).queue_url }

    specify "default behavior is no long polling" do
      start = Time.now
      response = sqs.receive_message(
        queue_url: queue_url
      )

      expect(response.messages.size).to eq 0
      expect(Time.now - start).to be < 0.5
    end

    specify "can configure long polling on queue" do
      start = Time.now
      response = sqs.receive_message(
        queue_url: long_polling_queue_url
      )

      expect(response.messages.size).to eq 0
      expect(Time.now - start).to be > 1
    end

    specify "specifying WaitTimeSeconds overrides queue configuration" do
      start = Time.now
      response = sqs.receive_message(
        queue_url: queue_url,
        wait_time_seconds: 1,
      )

      expect(response.messages.size).to eq 0
      expect(Time.now - start).to be > 1

      start = Time.now
      response = sqs.receive_message(
        queue_url: long_polling_queue_url,
        wait_time_seconds: 2,
      )

      expect(response.messages.size).to eq 0
      expect(Time.now - start).to be > 2

      start = Time.now
      response = sqs.receive_message(
        queue_url: long_polling_queue_url,
        wait_time_seconds: 0,
      )

      expect(response.messages.size).to eq 0
      expect(Time.now - start).to be < 0.5
    end

    specify "a non-empty result immediately returns without waiting" do
      body = "test 123"

      sqs.send_message(
        queue_url: queue_url,
        message_body: body
      )

      start = Time.now
      response = sqs.receive_message(
        queue_url: queue_url,
        wait_time_seconds: 1,
      )

      expect(response.messages.size).to eq 1
      expect(Time.now - start).to be < 0.5
    end
  end

  specify "DeleteMessage" do
    sqs.send_message(
      queue_url: queue_url,
      message_body: "test",
    )

    message1 = sqs.receive_message(
      queue_url: queue_url,
    ).messages.first

    let_messages_in_flight_expire

    sqs.delete_message(
      queue_url: queue_url,
      receipt_handle: message1.receipt_handle,
    )

    response = sqs.receive_message(
      queue_url: queue_url,
    )
    expect(response.messages.size).to eq 0
  end

  specify "DeleteMessageBatch" do
    sqs.send_message(
      queue_url: queue_url,
      message_body: "test1"
    )
    sqs.send_message(
      queue_url: queue_url,
      message_body: "test2"
    )

    messages_response = sqs.receive_message(
      queue_url: queue_url,
      max_number_of_messages: 2,
    )
    expect(messages_response.messages.size).to eq 2

    let_messages_in_flight_expire

    response = sqs.delete_message_batch(
      queue_url: queue_url,
      entries: messages_response.messages.map { |msg|
        {
          id: SecureRandom.uuid,
          receipt_handle: msg.receipt_handle,
        }
      },
    )
    expect(response.successful.size).to eq(2)

    messages_response = sqs.receive_message(
      queue_url: queue_url,
      max_number_of_messages: 2,
    )
    expect(messages_response.messages.size).to eq 0
  end

  specify "PurgeQueue" do
    sqs.send_message(
      queue_url: queue_url,
      message_body: "test1"
    )
    sqs.send_message(
      queue_url: queue_url,
      message_body: "test2"
    )

    sqs.purge_queue(
      queue_url: queue_url,
    )

    response = sqs.receive_message(
      queue_url: queue_url,
    )
    expect(response.messages.size).to eq 0
  end

  specify "DeleteQueue" do
    sent_message = sqs.send_message(
      queue_url: queue_url,
      message_body: "test1"
    )

    response = sqs.receive_message(
      queue_url: queue_url,
    )
    expect(response.messages[0].message_id).to eq sent_message.message_id
    expect(response.messages.size).to eq 1

    let_messages_in_flight_expire

    sqs.delete_queue(queue_url: queue_url)
    sqs.create_queue(queue_name: QUEUE_NAME)

    response = sqs.receive_message(
      queue_url: queue_url,
    )
    expect(response.messages.size).to eq 0
  end

  specify "SendMessageBatch" do
    bodies = %w(a b c)

    response = sqs.send_message_batch(
      queue_url: queue_url,
      entries: bodies.map { |bd|
        {
          id: SecureRandom.uuid,
          message_body: bd,
        }
      }
    )
    expect(response.successful.size).to eq(3)

    messages_response = sqs.receive_message(
      queue_url: queue_url,
      max_number_of_messages: 3,
    )
    expect(messages_response.messages.map(&:body)).to match_array bodies
  end

  specify "set message timeout to 0" do
    body = 'some-sample-message'

    sqs.send_message(
      queue_url: queue_url,
      message_body: body,
    )

    message = sqs.receive_message(
      queue_url: queue_url,
      visibility_timeout: 10,
    ).messages.first
    expect(message.body).to eq body

    sqs.change_message_visibility(
      queue_url: queue_url,
      receipt_handle: message.receipt_handle,
      visibility_timeout: 0,
    )

    same_message = sqs.receive_message(
      queue_url: queue_url,
    ).messages.first
    expect(same_message.body).to eq body
  end

  specify 'set message timeout and wait for message to come' do
    body = 'some-sample-message'

    sqs.send_message(
      queue_url: queue_url,
      message_body: body,
    )

    message = sqs.receive_message(
      queue_url: queue_url,
      visibility_timeout: 10,
    ).messages.first
    expect(message.body).to eq body

    sqs.change_message_visibility(
      queue_url: queue_url,
      receipt_handle: message.receipt_handle,
      visibility_timeout: 1,
    )

    nothing = sqs.receive_message(
      queue_url: queue_url,
    )
    expect(nothing.messages.size).to eq 0

    sleep(2)

    same_message = sqs.receive_message(
      queue_url: queue_url,
    ).messages.first
    expect(same_message.body).to eq body
  end

  specify 'should fail if trying to update the visibility_timeout for a message that is not in flight' do
    response = sqs.send_message(
      queue_url: queue_url,
      message_body: 'some-sample-message',
    )

    expect {
      sqs.change_message_visibility(
        queue_url: queue_url,
        receipt_handle: response.message_id,
        visibility_timeout: 30
      )
    }.to raise_error(Aws::SQS::Errors::MessageNotInflight)
  end

  specify 'ChangeMessageVisibilityBatch' do
    bodies = (1..10).map { |n| n.to_s }
    response = sqs.send_message_batch(
      queue_url: queue_url,
      entries: bodies.map { |bd|
        {
          id: SecureRandom.uuid,
          message_body: bd,
        }
      }
    )
    expect(response.successful.size).to eq(10)

    message = sqs.receive_message(
      queue_url: queue_url,
      max_number_of_messages: 10,
      visibility_timeout: 1,
    )
    expect(message.messages.size).to eq(10)

    response = sqs.change_message_visibility_batch(
      queue_url: queue_url,
      entries: message.messages.map { |m|
        {
          id: m.message_id,
          receipt_handle: m.receipt_handle,
          visibility_timeout: 10,
        }
      }
    )
    expect(response.successful.size).to eq(10)

    sleep(2)

    message = sqs.receive_message(
      queue_url: queue_url,
      max_number_of_messages: 10,
    )
    expect(message.messages.size).to eq(0)
  end

  specify 'should be moved to configured DLQ after maxReceiveCount if RedrivePolicy is set' do
    dlq_queue_url = sqs.create_queue(queue_name: "TestSourceQueueDLQ").queue_url

    dlq_arn = sqs.get_queue_attributes(queue_url: dlq_queue_url).attributes.fetch("QueueArn")
    sqs.set_queue_attributes(
      queue_url: queue_url,
      attributes: {
        "RedrivePolicy" => "{\"deadLetterTargetArn\":\"#{dlq_arn}\",\"maxReceiveCount\":2}"
      }
    )

    message_id = sqs.send_message(
      queue_url: queue_url,
      message_body: "test",
    ).message_id


    2.times do
      message = sqs.receive_message(queue_url: queue_url)
      expect(message.messages.size).to eq(1)
      expect(message.messages.first.message_id).to eq(message_id)
      expire_message(message.messages.first)
    end

    expect(sqs.receive_message(queue_url: queue_url).messages.size).to eq(0)

    message = sqs.receive_message(queue_url: dlq_queue_url)
    expect(message.messages.size).to eq(1)
    expect(message.messages.first.message_id).to eq(message_id)
  end

  def let_messages_in_flight_expire
    $fake_sqs.expire
  end

  def expire_message(message)
    sqs.change_message_visibility(
      queue_url: queue_url,
      receipt_handle: message.receipt_handle,
      visibility_timeout: 0,
    )
  end

end
