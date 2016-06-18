require "integration_spec_helper"

RSpec.describe "Actions for Queues", :sqs do

  let(:sqs) { Aws::SQS::Client.new }
  before do
    sqs.config.endpoint = $fake_sqs.uri
  end

  specify "CreateQueue" do
    response = sqs.create_queue(queue_name: "test-create-queue")
    expect(response.queue_url).to eq "http://localhost:4568/test-create-queue"
    response2 = sqs.get_queue_attributes(queue_url: response.queue_url)
    expect(response2.attributes.fetch("QueueArn")).to match %r"arn:aws:sqs:us-east-1:.+:test-create-queue"
  end

  specify "GetQueueUrl" do
    sqs.create_queue(queue_name: "test-get-queue-url")
    response = sqs.get_queue_url(queue_name: "test-get-queue-url")
    expect(response.queue_url).to eq "http://localhost:4568/test-get-queue-url"
  end

  specify "ListQueues" do
    sqs.create_queue(queue_name: "test-list-1")
    sqs.create_queue(queue_name: "test-list-2")
    expect(sqs.list_queues.queue_urls).to eq [
      "http://localhost:4568/test-list-1",
      "http://localhost:4568/test-list-2"
    ]
  end

  specify "ListQueues with prefix" do
    sqs.create_queue(queue_name: "test-list-1")
    sqs.create_queue(queue_name: "test-list-2")
    sqs.create_queue(queue_name: "other-list-3")
    expect(sqs.list_queues(queue_name_prefix: "test").queue_urls).to eq [
      "http://localhost:4568/test-list-1",
      "http://localhost:4568/test-list-2",
    ]
  end

  specify "DeleteQueue" do
    url = sqs.create_queue(queue_name: "test-delete").queue_url
    expect(sqs.list_queues.queue_urls.size).to eq 1
    sqs.delete_queue(queue_url: url)
    expect(sqs.list_queues.queue_urls.size).to eq 0
  end

  specify "SetQueueAttributes / GetQueueAttributes" do
    queue_url = sqs.create_queue(queue_name: "my-queue").queue_url


    sqs.set_queue_attributes(
      queue_url: queue_url,
      attributes: {
        "DelaySeconds" => "900"
      }
    )

    response = sqs.get_queue_attributes(
      queue_url: queue_url,
    )
    expect(response.attributes.fetch("DelaySeconds")).to eq "900"
  end

end
