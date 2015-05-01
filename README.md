# Takeout
[![Code Climate](https://codeclimate.com/repos/5541639ce30ba019b0006e87/badges/28282f2cfaa73331e16e/gpa.svg)](https://codeclimate.com/repos/5541639ce30ba019b0006e87/feed) [![Circle CI](https://circleci.com/gh/kylegrantlucas/ruby_api_client.svg?style=svg&circle-token=d4fcd95c980a36e8ccefe94abc317d6d58b4f14d)](https://circleci.com/gh/kylegrantlucas/ruby_api_client)

A simple wrapper for generating on-the-fly API clients.

## Requirements

Requires >= 2.1.0 MRI due to its use of keyword arguments. May work under implementations of Ruby but is currently untested.

## Installation

Add this line to your application's Gemfile:

    gem 'takeout'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install takeout

## Usage

### Quick Use

The first step is to instantiate a client with the URI and given endpoints you would like the gem to create methods for:

    client = Takeout::Client.new(uri: 'testing.com', endpoints: {get: [:test, :test2], post: :test2})

#### SSL Support

SSL is also supported, and it very easy to flip on.

You can either specify ssl when instantiating the object:

    client = Takeout::Client.new(uri: 'testing.com', endpoints: {get: :test}, ssl: true)

Or you can flip it on once already created:

    client.enable_ssl

You can disable it using the same method:

    client.disable_ssl

### Advanced Use
#### Headers

## Contributing

1. Fork it ( https://github.com/[my-github-username]/takeout/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
