module Takeout
  class Client
    require 'curb'
    require 'oj'
    require 'uri'

    attr_accessor :debug, :options, :headers
    attr_writer :ssl
    attr_reader :endpoints, :uri
    FAILURES = [:failure, :missing, :redirect]

    def initialize(uri=nil, endpoints={}, ssl=false, headers=nil, debug=false, options={})
      @uri, self.endpoints, @options, @headers, @debug, self.ssl = uri, endpoints, options, headers, debug, ssl
    end

    def ssl?
      return @ssl
    end

    def endpoints=(value)
      generate_endpoint_methods(value)
      @endpoints = value
    end

    def uri=(value)
      @uri = value
      @url = generate_url

    end

    def enable_ssl
      self.ssl=true
    end

    def disable_ssl
      self.ssl=false
    end

    private

    def generate_endpoint_methods(endpoints)
      endpoints.each do |request_type, endpoint_names|
        [endpoint_names].flatten(1).each do |request_name|
          self.class.send(:define_method, "#{request_type}_#{request_name}".to_sym) do |headers={}, object_id=nil, options={}|
            options.merge!(@options) if @options
            headers.merge!(@headers) if @headers
            request_url = object_id ? generate_object_id_request_url(object_id, request_name) : generate_request_url(request_name)

            return perform_curl_request(request_type, request_url, options, headers)
          end
        end
      end if endpoints.is_a? Hash
    end

    def perform_curl_request(request_type, request_url, options=nil, headers=nil)
      curl = Curl.send(request_type.to_sym, request_url.to_s, options) do |curl|
        curl.verbose = true if @debug

        headers.each { |key, value| curl.headers[key.to_s] = value } if headers

        curl.on_success {|response| @parsed_body, @failure = Oj.load(response.body_str), false }

        FAILURES.each { |failure_type| curl.send("on_#{failure_type}") {@failure=true} }
      end

      raise Takeout::EndpointFailureError.new(curl, request_type) if @failure

      return @parsed_body if @parsed_body
    end

    def generate_object_id_request_url(object_id, endpoint_name)
      url "/#{endpoint_name.to_s}/#{object_id}"
    end

    def generate_request_url(endpoint_name)
      url "/#{endpoint_name.to_s}"
    end

    def url(endpoint=nil)
      ssl? ? URI::HTTPS.build(host: @uri, path: endpoint) : URI::HTTP.build(host: @uri, path: endpoint)
    end
  end
end