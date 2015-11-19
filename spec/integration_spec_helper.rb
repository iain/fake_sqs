require "aws-sdk"
require "fake_sqs/test_integration"

# Aws.config[:credentials] = {
#   :use_ssl           => false,
#   :sqs_endpoint      => "localhost",
#   :sqs_port          => 4568,
#   :access_key_id     => "fake access key",
#   :secret_access_key => "fake secret key",
# }
Aws.config.update(
  region: "us-east-1",
  credentials: Aws::Credentials.new("fake", "fake"),
)

# See https://github.com/aws/aws-sdk-ruby/issues/777
Aws::SQS::Client.remove_plugin(Aws::Plugins::SQSQueueUrls)

db = ENV["SQS_DATABASE"] || ":memory:"
puts "\n\e[34mRunning specs with database \e[33m#{db}\e[0m"

$fake_sqs = FakeSQS::TestIntegration.new(
  database: db,
  sqs_endpoint: "localhost",
  sqs_port: 4568,
)

RSpec.configure do |config|
  config.before(:each, :sqs) { $fake_sqs.start }
  config.before(:each, :sqs) { $fake_sqs.reset }
  config.after(:suite) { $fake_sqs.stop }
end
