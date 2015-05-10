module Takeout
  class Client
    require 'curb'
    require 'oj'
    require 'uri'
    require 'erb'

    attr_accessor :debug, :options, :headers, :extension, :ssl, :schemas
    attr_reader :endpoints, :uri
    FAILURES = [:failure, :missing, :redirect]

    def initialize(uri:, endpoints:, schemas: {}, ssl: false, headers: nil, debug: false, **options)
      @uri, self.endpoints, @options, @headers, @debug, @ssl, @schemas = uri, endpoints, options, headers, debug, ssl, schemas
    end

    def ssl?
      return @ssl
    end

    def endpoints=(value)
      generate_endpoint_methods(value)
      @endpoints = value
    end

    def enable_ssl
      @ssl=true
    end

    def disable_ssl
      @ssl=false
    end

    private

    def generate_endpoint_methods(endpoints)
      endpoints.each do |request_type, endpoint_names|
        [endpoint_names].flatten(1).each do |request_name|
          self.class.send(:define_method, "#{request_type}_#{request_name}".to_sym) do |headers: {}, **options|
            options.merge!(@options) if @options
            headers.merge!(@headers) if @headers
            request_url = generate_request_url(request_name, request_type, options)
            request_url += ".#{options[:extension]}" if options[:extension]
            return perform_curl_request(request_type, request_url, options: options, headers: headers)
          end
        end
      end if endpoints.is_a? Hash
    end

    def substitute_template_values(endpoint, request_type, object_id=nil, options={})
      # Gets the proper template for the give CUSTOM_SCHEMA string for this endpoint and substitutes value for it based on give options
      endpoint_templates = @schemas.fetch(endpoint, nil)
      template = endpoint_templates.fetch(request_type, nil) if endpoint_templates
      extracted_options = {endpoint: endpoint, object_id: object_id}
      template.scan(/\[(\w+)\]/).flatten(1).each do |template_key|
        extracted_options.merge!(options.select {|key| key == template_key.to_sym }) if options.has_key? template_key.to_sym
        template = template.gsub("[#{template_key.to_s}]", ERB::Util.url_encode(extracted_options.fetch(template_key.to_sym, '').to_s))
      end if template

      return template
    end

    def perform_curl_request(request_type, request_url, options: nil, headers: nil)
      curl = Curl.send(request_type.to_sym, request_url.to_s, options) do |curl|
        curl.verbose = true if @debug
        if options[:basic_auth]
          curl.http_auth_types = :basic
          curl.username = options[:basic_auth][:username]
          curl.password = options[:basic_auth][:password]
        end


        headers.each { |key, value| curl.headers[key.to_s] = value } if headers

        curl.on_success {|response| @parsed_body, @failure = Oj.load(response.body_str), false }

        FAILURES.each { |failure_type| curl.send("on_#{failure_type}") {@failure=true} }
      end

      raise Takeout::EndpointFailureError.new(curl, request_type) if @failure

      return @parsed_body if @parsed_body
    end


    def generate_request_url(endpoint_name, request_type=nil, options=nil)
      custom_schema = substitute_template_values(endpoint_name, request_type, options) if request_type && options
      if options[:object_id]
        custom_schema ? url(custom_schema) : url("/#{endpoint_name.to_s}/#{options[:object_id]}")
      else
        custom_schema ? url(custom_schema) : url("/#{endpoint_name.to_s}")
      end

    end

    def url(endpoint=nil)
      ssl? ? URI::HTTPS.build(host: @uri, path: endpoint) : URI::HTTP.build(host: @uri, path: endpoint)
    end
  end
end