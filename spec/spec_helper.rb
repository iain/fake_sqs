require "aws-sdk"
require "fake_sqs/test_integration"

AWS.config(
  :use_ssl           => false,
  :sqs_endpoint      => "localhost",
  :sqs_port          => 4568,
  :access_key_id     => "fake access key",
  :secret_access_key => "fake secret key",
)

$fake_sqs = FakeSQS::TestIntegration.new

RSpec.configure do |config|

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.before(:suite) { $fake_sqs = FakeSQS::TestIntegration.new }
  config.before(:each, :sqs) { $fake_sqs.start }
  config.after(:suite) { $fake_sqs.stop }

end
