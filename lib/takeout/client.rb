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

    # @return [Hash] the hash containing the endpoints by request type to generate methods for
    attr_reader :endpoints

    # A constant specifying the kind of event callbacks to raise errors for
    FAILURES = [:failure, :missing, :redirect]

    # The main client initialization method.
    # ==== Attributes
    #
    # * +options+ - The main atrtibute and extra global options to set for the client
    # ==== Options
    #
    # * +:uri+ - A string defining the URI for the API to call.
    # * +:endpoints+ - A hash containing the endpoints by request type to generate methods for
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

    # Sets the instance variable and then generates the dynamic methods by calling #generate_enpoint_methods
    # @param [Hash] value A hash specifying the custom per-endpoint schema templates
    def endpoints=(value)
      generate_endpoint_methods(value)
      @endpoints = value
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

    # Generates the dynamic (request_type)_(endpoint_name) methods that allow you to access your API.
    # @param [Hash] endpoints A hash with the form {request_type: :endpoint_name} or {request_type: [:endpoint_name1, :endpoint_name_2]}
    def generate_endpoint_methods(endpoints)
      endpoints.each do |request_type, endpoint_names|
        # Force any give values into an array and then iterate over that
        [endpoint_names].flatten(1).each do |request_name|
          define_singleton_method("#{request_type}_#{request_name}".to_sym) do |options={}|
            # Extract values that we store separately from the options hash and then clean it up
            headers.merge!(options[:headers]) if options[:headers]

            # Merge in global options
            options.merge!(@options) if @options

            # Build the request_url and update the options to remove templated values (if there are any)
            request_url, options = generate_request_url(request_name, request_type, options)

            # Clean up options hash before performing request
            [:headers, :extension, :object_id].each { |value| options.delete(value)}

            return perform_curl_request(request_type, request_url, options, headers)
          end
        end
      end if endpoints.is_a? Hash
    end

    # Render out the template values and return the updated options hash
    # @param [String] endpoint
    # @param [String] request_type
    # @param [Hash] options
    # @return [String] rendered_template
    # @return [Hash] options
    def substitute_template_values(endpoint, request_type, options={})
      # Gets the proper template for the give CUSTOM_SCHEMA string for this endpoint and substitutes value for it based on give options
      endpoint_templates = @schemas.fetch(request_type, nil)
      template = endpoint_templates.fetch(endpoint, nil) if endpoint_templates

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

      # Convert keys to strings
      extracted_options = extracted_options.inject({}){|memo,(k,v)| memo[k.to_s] = v; memo}

      # Encode the template values and remove template values from original options hash
      extracted_options.each do |key, value|
        extracted_options[key] = ERB::Util.url_encode(value.to_s)
        options.delete(key.to_sym)
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

        curl.on_success {|response| @parsed_body, @failure = Oj.load(response.body_str), false }

        FAILURES.each { |failure_type| curl.send("on_#{failure_type}") {@failure=true} }
      end

      raise Takeout::EndpointFailureError.new(curl, request_type) if @failure

      return @parsed_body
    end


    def generate_request_url(endpoint_name, request_type=nil, options=nil)
      # Generate custom templated path string and update options hash
      custom_schema, options = substitute_template_values(endpoint_name, request_type, options) unless schemas.empty?

      # Generate URL based on if the custom schema exists, and if there is a given object_id
      request_url = if custom_schema.nil? || (custom_schema && custom_schema.empty?)
                      (options[:object_id] ? url("/#{endpoint_name.to_s}/#{options[:object_id]}") : url("/#{endpoint_name.to_s}"))
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
      self.endpoints = options[:endpoints] || {}
      @headers = options[:headers] || {}
      @schemas = options[:schemas] || {}
      @debug = options[:debug]
      @ssl = options[:ssl]
      @extension =  options[:extension]

      # Clean instance variables out of options hash and set that as options instance variable
      [:uri, :endpoints, :headers, :debug, :ssl, :schemas, :extension].each { |v| options.delete(v) }
      @options = options
    end

    def url(endpoint=nil)
      ssl? ? URI::HTTPS.build(host: @uri, path: endpoint) : URI::HTTP.build(host: @uri, path: endpoint)
    end
  end
end