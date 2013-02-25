# Fake SQS [![Build Status](https://secure.travis-ci.org/iain/fake_sqs.png)](http://travis-ci.org/iain/fake_sqs)

Inspired by [Fake DynamoDB] [fake_dynamo], this is an AWS SQS compatible
message queue that can be ran locally. This makes it ideal for integration
testing, just like you would have a local database running. Fake SQS doesn't
persist anything, not even the queues themselves. You'll have to create the
queues everytime you start it.

This implementation is **not complete** yet.

Done so far are:

* Creating queues
* Deleting queues
* Listing queues (with prefixes)
* Get queue url via the name
* Send messages (and in batch)
* Receive messages (and in batch)
* Deleting messages (and in batch)

Certain bits are left off on purpose, to make it easier to work with, such as:

* No checking on access keys or signatures
* No 60 second delay between deleting a queue and recreating it.
* No visibility timeouts (see below about special hooks)

Other parts are just not done yet:

* Permissions
* Changing queue attributes
* Changing message visibility
* Error handling

So, actually, just the basics are implemented at this point.

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

This is an example of how to configure the official [aws-sdk gem] [aws-sdk], to
let it talk to Fake SQS.

``` ruby
AWS.config(
  :use_ssl           => false,
  :sqs_endpoint      => "localhost",
  :sqs_port          => 4568,
  :access_key_id     => "access key id",
  :secret_access_key => "secret access key"
)
```

If you have the configuration options for other libraries, please give them to
me.

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


  [fake_dynamo]: https://github.com/ananthakumaran/fake_dynamo
  [aws-sdk]: https://github.com/amazonwebservices/aws-sdk-for-ruby
