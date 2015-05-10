# Takeout
[![Gem Version](https://badge.fury.io/rb/takeout.svg)](http://badge.fury.io/rb/takeout)
[![Code Climate](https://codeclimate.com/github/kylegrantlucas/takeout/badges/gpa.svg)](https://codeclimate.com/github/kylegrantlucas/takeout) 
[![Test Coverage](https://codeclimate.com/github/kylegrantlucas/takeout/badges/coverage.svg)](https://codeclimate.com/github/kylegrantlucas/takeout/coverage) 
[![Circle CI](https://circleci.com/gh/kylegrantlucas/takeout/tree/master.svg?style=shield)](https://circleci.com/gh/kylegrantlucas/takeout/tree/master) 
[![Inline docs](http://inch-ci.org/github/kylegrantlucas/takeout.svg?branch=master&style=shields)](http://inch-ci.org/github/kylegrantlucas/takeout) 
[![Join the chat at https://gitter.im/kylegrantlucas/takeout](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/kylegrantlucas/takeout?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Analytics](https://ga-beacon.appspot.com/UA-62799576-1/kylegrantlucas/takeout?pixel)](https://github.com/igrigorik/ga-beacon)

A powerful little tool for generating on-the-fly API clients.

## Requirements

All versions of MRI 1.9.3+ and up are supported (and tested via CircleCI), the gem is currently unsupported on JRuby, MRI 1.8-1.9.2, and Rubinus.
Support of these platforms is a future goal for the project.

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

This can also be done using block format:
   
    client = Takeout::Client.new do |client|
      client.uri = 'testing.com'
      client.endpoints = {get: [:test, :test2], post: :test2}
    end
    
From here you can begin calling your api methods! They take on the form ```(request_type)_(endpoint_name)```
So given the example instantiation our method list would look like:

    client.get_test
    client.get_test2
    client.post_test2
    
You can at anytime see a list of the methods available to you by running this:

    (client.methods - Object.methods - Takeout::Client.instance_methods(false))
    
Results are returned as parsed ruby objects:

    client.get_test
      #=> {test: 1}
      
### Options
#### Extensions

You have the ability to specify an extension that gets tacked on, if you need it.
You may do this in either the call or in the client instantiation, however the call will always override the clients extension if there is a conflict.

    client = Takeout::Client.new do |client|
      client.uri = 'testing.com'
      client.endpoints = {get: [:test, :test2], post: :test2}
      client.extension = 'json'
    end
    
    client.get_test(extension: 'json')
    
#### Templating

Takeout includes support for specifying customs endpoint schemas using the [Liquid Templating Engine](http://liquidmarkup.org):
    
To define a schema do so in the instantiation of the client:

    client = Takeout::Client.new do |client|
      client.uri = 'testing.com'
      client.endpoints = {get: [:test, :test2], post: :test2}
      client.schemas = {get: {test: '/{{endpoint}}{% if param %}/required-param-{{param}}{% endif %}'}
    end
    
From there when you call the endpoint you may pass in your params as part of the options and it will fill in accordingly:

    client.get_test(param: 'Testing')
      URL => "http://testing.com/test/required-param-Testing
        
    client.get_test
      URL => "http://testing.com/test"
        
As you can see in the above example I use ```{{endpoint}}``` as one of the template values, it is only one of two reserved keywords for the templates, the other is ```{{object_id}}```.

#### SSL Support

SSL is also supported, and is very easy to flip on.

You can either specify ssl when instantiating the object:

    client = Takeout::Client.new(uri: 'testing.com', endpoints: {get: :test}, ssl: true)

Or you can flip it on once already created:

    client.enable_ssl

You can disable it using the same method:

    client.disable_ssl

#### Headers

Takeout also feature full support for headers:

    client = Takeout::Client.new do |client|
      client.uri = 'testing.com'
      client.endpoints = {get: [:test, :test2], post: :test2}
      client.headers = {auth_token: 'asdjhdskjfh23423423'}
    end

Much like extensions this can be done in the endpoint call too, and it will merge with the clients global headers:

    client.get_test(headers: {auth_token: 'asdjhdskjfh23423423'})

#### Basic Authentication

Takeout also has support for basic auth by specifying both the ```username``` and ```password``` options during a call or instantiation
Unlike most other features these are simply passed as options to the call:

    client = Takeout::Client.new do |client|
      client.uri = 'testing.com'
      client.endpoints = {get: [:test, :test2], post: :test2}
      client.options = {username: 'user', password: 'pass'}
    end
    
    client.get_test(username: 'user', password: 'pass')

## Contributing

1. Fork it ( https://github.com/[my-github-username]/takeout/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
