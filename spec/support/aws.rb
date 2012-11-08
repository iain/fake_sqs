require 'aws-sdk'
require 'fake_sqs'
require 'faraday'
require 'uri'
require 'thin'

Thread.abort_on_exception = true

ENV['RACK_ENV'] = 'test'

require 'webmock/rspec'
WebMock.disable_net_connect!(:allow_localhost => true)

Thin::Logging.silent = true

class FakeServer

  attr_reader :url

  def initialize(url = "http://0.0.0.0:4567")
    @url = url
  end

  def uri
    @uri ||= URI.parse(url)
  end

  def port
    uri.port
  end

  def host
    uri.host
  end

  def ssl?
    uri.scheme == "https"
  end

  def start
    return if @started
    @started = true
    @fake_sqs_thread = Thread.new {
      load File.expand_path('../../../bin/fake_sqs', __FILE__)
    }
    wait_until_up
  end

  def stop
    @fake_sqs_thread.kill
  end

  def reset
    Faraday.delete(url)
  end

  def expire_messages_in_flight
    Faraday.put(url)
  end

  def wait_until_up(tries = 0)
    fail "Server didn't start in time" if tries > 200
    response = Faraday.get(url)
    if response.status != 200
      wait_until_up(tries + 1)
    end
  rescue Faraday::Error::ConnectionFailed
    wait_until_up(tries + 1)
  end

end

$fake_server = FakeServer.new

module FakeServerHelper

  def let_messages_in_flight_expire
    $fake_server.expire_messages_in_flight
  end

end

AWS.config(
  :use_ssl           => $fake_server.ssl?,
  :sqs_endpoint      => $fake_server.host,
  :sqs_port          => $fake_server.port,
  :access_key_id     => "access key id",
  :secret_access_key => "secret access key"
)


RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.before(:suite) { $fake_server.start }
  config.after(:suite)  { $fake_server.stop }
  config.before(:each, :acceptance) { $fake_server.reset }
  config.include FakeServerHelper
end
