require 'support/aws'

describe "Actions for Queues", :acceptance do

  let(:sqs) { AWS::SQS.new }

  specify "CreateQueue" do
    queue = sqs.queues.create("test-create-queue")
    queue.url.should eq "http://0.0.0.0:4567/test-create-queue"
  end

  specify "GetQueueUrl" do
    sqs.queues.create("test-get-queue-url")
    queue = sqs.queues.named("test-get-queue-url")
    queue.url.should eq "http://0.0.0.0:4567/test-get-queue-url"
  end

  specify "ListQueues" do
    sqs.queues.create("test-list-1")
    sqs.queues.create("test-list-2")
    queues = sqs.queues.map(&:url).should eq [
      "http://0.0.0.0:4567/test-list-1",
      "http://0.0.0.0:4567/test-list-2"
    ]
  end

  specify "ListQueues with prefix" do
    sqs.queues.create("test-list-1")
    sqs.queues.create("test-list-2")
    sqs.queues.create("other-list-3")
    queues = sqs.queues.with_prefix("test").map(&:url).should eq [
      "http://0.0.0.0:4567/test-list-1",
      "http://0.0.0.0:4567/test-list-2"
    ]
  end

  specify "DeleteQueue" do
    url = sqs.queues.create("test-delete").url
    sqs.should have(1).queues
    sqs.queues[url].delete
    sqs.should have(0).queues
  end

end
