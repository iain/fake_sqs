require 'fake_sqs/message'

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
