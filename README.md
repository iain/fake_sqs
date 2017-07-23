# Fake SQS [![Build Status](https://api.travis-ci.org/iain/fake_sqs.svg?branch=master)](http://travis-ci.org/iain/fake_sqs) [![Gem Version](https://badge.fury.io/rb/fake_sqs.svg)](https://badge.fury.io/rb/fake_sqs)

Fake SQS is a lightweight server that mocks the Amazon SQS API.

It is extremely useful for testing SQS applications in a sandbox environment without actually
making calls to Amazon, which not only requires a network connection, but also costs
money.

Many features are supported and if you miss something, open a pull.

## Installation

```
gem install fake_sqs
```

## Running

```
fake_sqs --database /path/to/database.yml
```

## Development

```
bundle install
rake
```
