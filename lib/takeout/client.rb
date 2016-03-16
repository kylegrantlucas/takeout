require 'takout/core/ext/nil_class'
module Takeout
  class Client
    require 'curb'
    require 'oj'
    require 'uri'
    require 'erb'
    require 'liquid'

    # @return [Boolean] a boolean specifying whether or not to run curl with teh verbose setting
    attr_accessor :debug

    # @return [Hash] a hash specifying the global options to apply to each request
    attr_accessor :options

    # @return [Hash] a hash specifying the headers to apply to each request
    attr_accessor :headers

    # @return [String] a string with the extension to be appended on each request
    attr_accessor :extension

    # @return [Boolean] a boolean to specify whether or not SSL is turned on
    attr_accessor :ssl

    # @return [Hash] a hash specifying the custom per-endpoint schema templates
    attr_accessor :schemas

    # @return [String] the uri to send requests to
    attr_accessor :uri

    attr_accessor :port
    
    attr_accessor :endpoint_prefix

    # A constant specifying the kind of event callbacks and if they should or should not raise an error
    CALLBACKS = {failure: true, missing: true}

    # The main client initialization method.
    # ==== Attributes
    #
    # * +options+ - The main atrtibute and extra global options to set for the client
    # ==== Options
    #
    # * +:uri+ - A string defining the URI for the API to call.
    # * +:headers+ - A hash specifying the headers to apply to each request
    # * +:ssl+ - A boolean to specify whether or not SSL is turned on
    # * +:schemas+ - A hash specifying the custom per-endpoint schema templates
    # * +:extension+ - A string with the extension to be appended on each request
    def initialize(options={})
      if block_given?
        yield self
      else
        extract_instance_variables_from_options(options)
      end
    end

    # Check if SSL is enabled.
    # @return [Boolean] Returns true if SSL is enabled, false if disabled
    def ssl?
      return @ssl
    end

    # Check if a port is specified.
    # @return [Boolean] Returns true if a port is enabled, false if nil.
    def port?
      return !port.nil?
    end

    # Flips the @ssl instance variable to true
    def enable_ssl
      @ssl=true
    end

    # Flips the @ssl instance variable to false
    def disable_ssl
      @ssl=false
    end

    private

    # Render out the template values and return the updated options hash
    # @param [String] endpoint
    # @param [String] request_type
    # @param [Hash] options
    # @return [String] rendered_template
    # @return [Hash] options
    def substitute_template_values(endpoint, request_type, options={})
      # Gets the proper template for the give CUSTOM_SCHEMA string for this endpoint and substitutes value for it based on give options
      endpoint_templates = @schemas.fetch(request_type.to_sym, nil)
      template = endpoint_templates.fetch(endpoint.to_sym, nil) if endpoint_templates

      if template
        extracted_options, options = extract_template_options(options.merge({endpoint: endpoint}), template)
        # Render out the template
        rendered_template = Liquid::Template.parse(template).render(extracted_options)
      end

      return rendered_template, options
    end

    def extract_template_options(options, template)
      extracted_options = {}

      # Build new options hash for templating
      extracted_options.merge!({endpoint: options[:endpoint]}) if options[:object_id]
      extracted_options.merge!({object_id: options[:object_id]}) if options[:object_id]
      template.scan(/\{\{(\w+)\}\}/).flatten(1).each { |template_key| extracted_options.merge!(options.select {|key| key == template_key.to_sym }) }

      # Convert keys to strings, encode values, clean up hash
      extracted_options = extracted_options.inject({}) do |memo,(key,value)|
        options.delete(key)
        memo.merge({key.to_s => ERB::Util.url_encode(value)})
      end

      return extracted_options, options
    end

    def perform_curl_request(request_type, request_url, options=nil, headers=nil)
      curl = Curl.send(request_type, request_url.to_s, options) do |curl|
        curl.verbose = true if @debug
        curl.headers = headers if headers

        if options[:username] && options[:password]
          curl.http_auth_types = :basic
          curl.username = options[:username]
          curl.password = options[:password]
        end

        CALLBACKS.each { |callback_type,failure| curl.send("on_#{callback_type}") {|response| @failure = failure}}
      end

      raise Takeout::EndpointFailureError.new(curl, request_type, @parsed_body) if @failure

      return Takeout::Response.new(headers: parse_response_headers(curl.head), body: Oj.load(curl.body_str), response: curl)
    end


    def generate_request_url(endpoint_name, request_type=nil, options=nil)
      # Generate custom templated path string and update options hash
      custom_schema, options = substitute_template_values(endpoint_name, request_type, options) unless schemas.empty?

      # Generate URL based on if the custom schema exists, and if there is a given object_id
      request_url = if custom_schema.nil? || (custom_schema && custom_schema.empty?)
        (options[:object_id] ? url("#{@endpoint_prefix}/#{endpoint_name.to_s}/#{options[:object_id]}") : url("#{@endpoint_prefix}/#{endpoint_name.to_s}"))
      else
        url(custom_schema)
      end

      # Append extension if one is given
      request_url = append_extension(request_url, options)
      
      return request_url, options
    end

    def append_extension(request_url, options)
      request_url = "#{request_url}.#{options[:extension] || self.extension}" if options[:extension] || self.extension
      return request_url
    end

    def extract_instance_variables_from_options(options)
      # Set instance variables
      @uri = options[:uri] || ''
      @headers = options[:headers] || {}
      @schemas = options[:schemas] || {}
      @debug = options[:debug]
      @ssl = options[:ssl]
      @extension =  options[:extension]
      @endpoint_prefix = options[:endpoint_prefix]
      @port = options[:port]

      # Clean instance variables out of options hash and set that as options instance variable
      [:uri, :endpoints, :headers, :debug, :ssl, :schemas, :extension, :endpoint_prefix, :port].each { |v| options.delete(v) }
      @options = options
    end

    def url(endpoint=nil)
      opts = port? ? {host: @uri, path: endpoint, port: @port} : {host: @uri, path: endpoint}
      ssl? ? URI::HTTPS.build(opts) : URI::HTTP.build(opts)
    end

    def parse_response_headers(header_string)
      header_string.split("\r\n")[1..-1].map {|x| {x.split(': ')[0].to_sym => x.split(': ')[1]} }.reduce({}, :update) if header_string && !header_string.empty?
    end

    def method_missing(method_sym, *attributes, &block)
      request_type = method_sym.to_s.scan(/^(?:get|post|put|delete|patch|update)/).first
      request_name = method_sym.to_s.scan(/(?<=_{1}).*/).first
      if (request_type && request_name)
        self.define_singleton_method(method_sym) do |options={}, &block|
          # Extract values that we store separately from the options hash and then clean it up
          headers.merge!(options[:headers]) if options[:headers]

          # Merge in global options
          options.merge!(@options) if @options

          # Build the request_url and update the options to remove templated values (if there are any)
          request_url, options = generate_request_url(request_name, request_type, options)

          # Clean up options hash before performing request
          [:headers, :extension, :object_id, :endpoint].each { |value| options.delete(value)}

          return perform_curl_request(request_type, request_url, options, headers)
        end

        self.send(method_sym, *attributes, &block)
      else
        super
      end
    end
  end
end