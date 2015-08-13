# Fake SQS [![Build Status](https://secure.travis-ci.org/iain/fake_sqs.png)](http://travis-ci.org/iain/fake_sqs)

Inspired by [Fake DynamoDB] [fake_dynamo], this is an AWS SQS compatible
message queue that can be ran locally. This makes it ideal for integration
testing, just like you would have a local database running. Fake SQS doesn't
persist anything, not even the queues themselves. You'll have to create the
queues everytime you start it.

This implementation is **not complete** yet, but should be useful already.

Done so far are:

* Creating queues
* Deleting queues
* Listing queues (with prefixes)
* Get queue url via the name
* Send messages (and in batch)
* Receive messages (and in batch)
* Deleting messages (and in batch)
* Changing queue attributes (but not all, and no validation)
* Setting visibility timeouts for messages
* Purge Queue

Certain bits are left off on purpose, to make it easier to work with, such as:

* No checking on access keys or signatures
* No 60 second delay between deleting a queue and recreating it.

Other parts are just not done yet:

* Permissions
* Error handling

So, actually, just the basics are implemented at this point.

PS. There is also [Fake SNS] [fake_sns].

## Usage

To install:

```
$ gem install fake_sqs
```

To start:

```
$ fake_sqs
```

To configure, see the options in the help:

```
$ fake_sqs --help
```

By default, FakeSQS uses an in-memory database (just a hash actually). To make
it persistant, run with:

```
$ fake_sqs --database /path/to/database.yml
```

Messages are not persisted, just the queues.

This is an example of how to configure the official [aws-sdk gem] [aws-sdk], to
let it talk to Fake SQS.

``` ruby
Aws.config.update(
    credentials: Aws::Credentials.new("fake", "fake"),
)
```
If you have the configuration options for other libraries, please give them to
me. The rest of the Aws configuration will lie in the `fake_sqs`-object you instantiate with 
this gem (see the example for how your `spec_helper.rb`-file should look like below.

To reset the entire server, during tests for example, send a DELETE request to
the server. For example:

```
$ curl -X DELETE http://localhost:4568/
```

Within SQS, after receiving, messages will be available again automatically
after a certain time. While this is not implemented (for now at least), you can
trigger this behavior at at will, with a PUT request.

```
$ curl -X PUT http://localhost:4568/
```


### Test Integration

When making integration tests for your app, you can easily include Fake SQS.

Here are the methods you need to run FakeSQS programmatically.

``` ruby
require "fake_sqs/test_integration"

# globally, before the test suite starts:
Aws.config.update(
  credentials: Aws::Credentials.new("fake", "fake"),
)

db = ENV["SQS_DATABASE"] || ":memory:"

$fake_sqs = FakeSQS::TestIntegration.new(
    database: db,
    sqs_endpoint: "localhost",
    sqs_port: 4568,
)

# before each test that requires SQS:
$fake_sqs.start

# at the end of the suite:
at_exit {
  $fake_sqs.stop
}
```

By starting it like this it will start when needed, and reset between each test.

Here's an example for RSpec to put in `spec/spec_helper.rb`:

``` ruby
require 'aws-sdk'
require 'fake_sqs/test_integration'

# AWS Config for local fake SQS
Aws.config.update(
    region: "us-east-1",
    credentials: Aws::Credentials.new("fake", "fake"),
)

# get SQS database configuration from environment, or just use memory (the default option)
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

```

Now you can use the `:sqs metadata to enable SQS integration:

``` ruby
describe "something with sqs", :sqs do
  it "creates a queue called 'my-queue'" do
    client = Aws::SQS::Client.new(region: 'us-east-1')
    client.config.endpoint = $fake_sqs.uri
    client.create_queue({queue_name: "my-queue"})
  end
end
```

## Development

Run all the specs:

```
$ rake
```

This will run the unit tests, then the acceptance tests for both types of
storage (in-memory and on disk).

When debugging an acceptance test, you can run it like this, which will redirect
output to the console:

```
$ DEBUG=true SQS_DATABASE=tmp/sqs.yml rspec spec/acceptance
```


  [fake_dynamo]: https://github.com/ananthakumaran/fake_dynamo
  [aws-sdk]: https://github.com/amazonwebservices/aws-sdk-for-ruby
  [fake_sns]: https://github.com/yourkarma/fake_sns
