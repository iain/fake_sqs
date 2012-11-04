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

  def create_message(options = {})
    FakeSQS::Message.new({"MessageBody" => "test"}.merge(options))
  end

end
