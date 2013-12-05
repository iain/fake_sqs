require "spec_helper"

describe "Actions for Queues", :sqs do

  let(:sqs) { AWS::SQS.new }

  specify "CreateQueue" do
    queue = sqs.queues.create("test-create-queue")
    queue.url.should eq "http://0.0.0.0:4568/test-create-queue"
    queue.arn.should match %r"arn:aws:sqs:us-east-1:.+:test-create-queue"
  end

  specify "GetQueueUrl" do
    sqs.queues.create("test-get-queue-url")
    queue = sqs.queues.named("test-get-queue-url")
    queue.url.should eq "http://0.0.0.0:4568/test-get-queue-url"
  end

  specify "ListQueues" do
    sqs.queues.create("test-list-1")
    sqs.queues.create("test-list-2")
    sqs.queues.map(&:url).should eq [
      "http://0.0.0.0:4568/test-list-1",
      "http://0.0.0.0:4568/test-list-2"
    ]
  end

  specify "ListQueues with prefix" do
    sqs.queues.create("test-list-1")
    sqs.queues.create("test-list-2")
    sqs.queues.create("other-list-3")
    sqs.queues.with_prefix("test").map(&:url).should eq [
      "http://0.0.0.0:4568/test-list-1",
      "http://0.0.0.0:4568/test-list-2",
    ]
  end

  specify "DeleteQueue" do
    url = sqs.queues.create("test-delete").url
    sqs.should have(1).queues
    sqs.queues[url].delete
    sqs.should have(0).queues
  end

  specify "SetQueueAttributes / GetQueueAttributes" do

    policy = AWS::SQS::Policy.new
    policy.allow(
      :actions => ['s3:PutObject'],
      :resources => "arn:aws:s3:::mybucket/mykey/*",
      :principals => :any
    ).where(:acl).is("public-read")

    queue = sqs.queues.create("my-queue")
    queue.policy = policy

    reloaded_queue = sqs.queues.named("my-queue")
    reloaded_queue.policy.should eq policy
  end

end
