require 'sinatra/base'

class FakeTestApi < Sinatra::Base
  REQUEST_TYPES = [:get, :put, :post, :delete]
  #
  # /posts endpoints
  #
  get('/posts') {json_response 200, 'posts.json'}
  post('/posts') {json_response 200, 'post.json'}
  delete('/posts') {json_response 404, nil}
  put('/posts') {json_response 404, nil}

  #
  # /posts/1 endpoints
  #
  get('/posts/1') {json_response 200, 'post.json'}
  delete('/posts/1') {json_response 200, 'post.json'}
  put('/posts/1') {json_response 200, 'post.json'}
  post('/posts/1') {json_response 404, nil}

  #
  # /fake_failure
  #
  REQUEST_TYPES.each {|rt| self.superclass.send(rt, '/fake_failure') {json_response 500, nil}}

  #
  # /fake_missing
  #
  REQUEST_TYPES.each {|rt| self.superclass.send(rt, '/fake_missing') {json_response 404, nil}}

  #
  # /fake_redirect
  #
  REQUEST_TYPES.each {|rt| self.superclass.send(rt, '/fake_redirect') {json_response 301, nil}}

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.open(File.dirname(__FILE__) + '/fixtures/' + file_name, 'rb').read if file_name
  end
end