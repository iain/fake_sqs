require 'fake_sqs/message'

RSpec.describe FakeSQS::Message do

  describe "#body" do

    it "is extracted from the MessageBody" do
      message = create_message("MessageBody" => "abc")
      expect(message.body).to eq "abc"
    end

  end

  describe "#md5" do

    it "is calculated from body" do
      message = create_message("MessageBody" => "abc")
      expect(message.md5).to eq "900150983cd24fb0d6963f7d28e17f72"
    end

  end

  describe "#id" do

    it "is generated" do
      message = create_message
      expect(message.id.size).to eq 36
    end

  end

  describe 'visibility_timeout' do

    let :message do
      create_message
    end

    it 'should default to nil' do
      expect(message.visibility_timeout).to eq nil
    end

    it 'should be expired when it is nil' do
      expect(message).to be_expired
    end

    it 'should be expired if set to a previous time' do
      message.visibility_timeout = Time.now - 1
      expect(message).to be_expired
    end

    it 'should not be expired at a future date' do
      message.visibility_timeout = Time.now + 1
      expect(message).not_to be_expired
    end

    it 'should not be expired when set to expire at a future date' do
      message.expire_at(5)
      expect(message.visibility_timeout).to be >=(Time.now + 4)
    end

  end

  def create_message(options = {})
    FakeSQS::Message.new({"MessageBody" => "test"}.merge(options))
  end

end
