require 'fake_sqs/message'
require 'rspec/collection_matchers'

describe FakeSQS::Message do

  describe "#body" do

    it "is extracted from the MessageBody" do
      message = create_message("MessageBody" => "abc")
      message.body.should eq "abc"
    end

  end

  describe "#md5" do

    it "is calculated from body" do
      message = create_message("MessageBody" => "abc")
      message.md5.should eq "900150983cd24fb0d6963f7d28e17f72"
    end

  end

  describe "#message_attributes" do

    it "has message attributes" do
        message = create_message("MessageBody" => "abc",
                                 "MessageAttribute.1.Name" => "one",
                                 "MessageAttribute.1.StringValue" => "A String Value",
                                 "MessageAttribute.1.DataType" => "String",
                                 "MessageAttribute.2.Name" => "two",
                                 "MessageAttribute.2.StringValue" => "35",
                                 "MessageAttribute.2.DataType" => "Number",
                                 "MessageAttribute.3.Name" => "three",
                                 "MessageAttribute.3.BinaryValue" => "c29tZSBiaW5hcnkgZGF0YQ==",
                                 "MessageAttribute.3.DataType" => "Binary")

        message.message_attributes.should have(3).items
        message.message_attributes_md5.should eq "6d31a67b8fa3c1a74d030c5de73fd7e2"
    end

    it "calculates string attribute md5" do

        message = create_message("MessageBody" => "abc",
                              "MessageAttribute.1.Name" => "one",
                              "MessageAttribute.1.StringValue" => "A String Value",
                              "MessageAttribute.1.DataType" => "String")
        message.message_attributes_md5.should eq "88bb810f131daa54b83485598cc35693"
    end

    it "calculates number attribute md5" do
        message = create_message("MessageBody" => "abc",
                              "MessageAttribute.1.Name" => "two",
                              "MessageAttribute.1.StringValue" => "35",
                              "MessageAttribute.1.DataType" => "Number")
        message.message_attributes_md5.should eq "7eb7af82e3ed82aef934e78b9ed11f12"
    end

    it "calculates binary attribute md5" do
        message = create_message("MessageBody" => "abc",
                              "MessageAttribute.1.Name" => "three",
                              "MessageAttribute.1.BinaryValue" => "c29tZSBiaW5hcnkgZGF0YQ==",
                              "MessageAttribute.1.DataType" => "Binary")
        message.message_attributes_md5.should eq "c0f297612d491707df87d6444ecb4817"
    end


  end

  describe "#id" do

    it "is generated" do
      message = create_message
      message.id.should have(36).characters
    end

  end

  describe 'visibility_timeout' do

    let :message do
      create_message
    end

    it 'should default to nil' do
      message.visibility_timeout.should be_nil
    end

    it 'should be expired when it is nil' do
      message.should be_expired
    end

    it 'should be expired if set to a previous time' do
      message.visibility_timeout = Time.now - 1
      message.should be_expired
    end

    it 'should not be expired at a future date' do
      message.visibility_timeout = Time.now + 1
      message.should_not be_expired
    end

    it 'should not be expired when set to expire at a future date' do
      message.expire_at(5)
      message.visibility_timeout.should be >=(Time.now + 4)
    end

  end

  def create_message(options = {})
    FakeSQS::Message.new({"MessageBody" => "test"}.merge(options))
  end

end
