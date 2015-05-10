require 'spec_helper'
ENDPOINTS = [:posts, :fake_failure, :fake_missing, :fake_redirect]
describe Takeout::Client do
  let (:client) {Takeout::Client.new(uri: 'test.com', endpoints: {get: ENDPOINTS, post: ENDPOINTS, put: ENDPOINTS, delete: ENDPOINTS})}

  context 'initialization' do
    pending 'creates methods for all provided endpoints'
    pending 'creates proper url'
  end

  context 'ssl' do
    it 'uses https protocol when enabled' do
      client.enable_ssl
      expect(client.send(:url).scheme).to eql 'https'
    end

    it 'uses http protocol when disabled' do
      client.disable_ssl
      expect(client.send(:url).scheme).to eql 'http'
    end
  end

  context 'templating' do
    pending 'properly substitutes template keys'
    pending 'properly handsles an object_id'
  end


  context 'headers' do
    pending 'submits headers'
    pending 'merges instance headers with call headers'
  end

  context 'options' do
    pending 'merges instance options with call options'
  end

  context 'get' do
    it 'returns array on success' do
      expect(client.get_posts).to be_an(Array)
    end

    it 'raises EndpointFailureError on missing' do
      expect{client.get_fake_missing}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:get, 'fake_missing'))
    end

    it 'raises EndpointFailureError on failure' do
      expect{client.get_fake_failure}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:get, 'fake_failure'))
    end
    pending 'raises EndPointFailureError on redirect'
  end

  context 'post' do
    it 'returns hash on success' do
      expect(client.post_posts).to be_an(Hash)
    end

    it 'raises EndpointFailureError when called without object_id' do
      expect{client.post_posts(object_id: 1)}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:post, 'posts/1'))
    end

    it 'raises EndpointFailureError on missing' do
      expect{client.post_fake_missing}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:post, 'fake_missing'))
    end
    it 'raises EndpointFailureError on failure' do
      expect{client.post_fake_failure}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:post, 'fake_failure'))
    end

    pending 'raises EndpointFailureError on redirect'
  end

  context 'delete' do
    it 'returns hash on success with object_id' do
      expect(client.delete_posts(object_id: 1)).to be_a(Hash)
    end

    it 'raises EndpointFailureError when called without object_id' do
      expect{client.delete_posts}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:delete, 'posts'))
    end

    it 'raises EndpointFailureError on missing' do
      expect{client.delete_fake_missing}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:delete, 'fake_missing'))
    end

    it 'raises EndpointFailureError on failure' do
      expect{client.delete_fake_failure}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:delete, 'fake_failure'))
    end

    pending 'raises EndPointFailureError on redirect'
  end

  context 'put' do
    it 'returns hash on success with object_id' do
      expect(client.put_posts(object_id: 1)).to be_a(Hash)
    end

    it 'raises EndpointFailureError when called without object_id' do
      expect{client.put_posts}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:put, 'posts'))
    end

    it 'raises EndpointFailureError on missing' do
      expect{client.put_fake_missing}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:put, 'fake_missing'))
    end
    it 'raises EndpointFailureError on failure' do
      expect{client.put_fake_failure}.to raise_error(Takeout::EndpointFailureError, generate_error_message(:put, 'fake_failure'))
    end
    pending 'raises EndPointFailureError on redirect'
  end
end

def generate_error_message(request_type, endpoint)
  codes = {fake_failure: 500, fake_missing: 404, fake_redirect: 301, :'posts/1' => 404, posts: 404}
  return "Error in calling #{request_type.to_s.upcase} on the endpoint: http://test.com/#{endpoint}, response_code: #{codes[endpoint.to_sym]}"
end