require 'fake_sqs/web_interface'
require 'rack/test'

RSpec.describe FakeSQS::WebInterface do
  include Rack::Test::Methods

  def app
    FakeSQS::WebInterface
  end

  it "responds to GET /ping" do
    get "/ping"
    expect(last_response).to be_ok
  end
end
