module Takeout
  class Client
    require 'curb'
    require 'oj'
    require 'uri'
    require 'erb'
    require 'liquid'

    attr_accessor :debug, :options, :headers, :extension, :ssl, :schemas, :uri, :extension
    attr_reader :endpoints
    FAILURES = [:failure, :missing, :redirect]

    def initialize(options={})
      if block_given?
        yield self
      else
        # Set instance variables
        @uri = options[:uri] ? options[:uri] : ''
        self.endpoints = options[:endpoints] ? options[:endpoints] : {}
        @headers = options[:headers] ? options[:headers] : {}
        @debug = options[:debug] ? options[:debug] : false
        @ssl = options[:ssl] ? options[:ssl] : false
        @schemas = options[:schemas] ? options[:schemas] : {}
        @extension =  options[:extension] ? options[:extension] : nil

        # Clean instance variables out of options hash and set that as options instance variable
        [:uri, :endpoints, :headers, :debug, :ssl, :schemas, :extension].each { |v| options.delete(v) }
        @options = options
      end
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
        # Force any give values into an array and then iterate over that
        [endpoint_names].flatten(1).each do |request_name|
          self.class.send(:define_method, "#{request_type}_#{request_name}".to_sym) do |options={}|
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

    def substitute_template_values(endpoint, request_type, options={})
      # Gets the proper template for the give CUSTOM_SCHEMA string for this endpoint and substitutes value for it based on give options
      endpoint_templates = @schemas.fetch(request_type, nil)
      template = endpoint_templates.fetch(endpoint, nil) if endpoint_templates

      # Build new options hash for templating
      extracted_options = {'endpoint' => endpoint}
      extracted_options.merge!({'object_id' => options[:object_id]})
      template.scan(/\{\{(\w+)\}\}/).flatten(1).each do |template_key|
        extracted_options.merge!(options.select {|key| key == template_key.to_sym }) if options.has_key? template_key.to_sym
      end if template

      # Convert keys to strings
      extracted_options = extracted_options.inject({}){|memo,(k,v)| memo[k.to_s] = v; memo}
      
      # Encode the template values and remove template values from original options hash
      extracted_options.each do |key, value|
        extracted_options[key] = ERB::Util.url_encode(value.to_s)
        options.delete(key.to_sym)
      end

      # Render out the template
      liquid_render = Liquid::Template.parse(template).render(extracted_options)

      return liquid_render, options
    end

    def perform_curl_request(request_type, request_url, options=nil, headers=nil)
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
      custom_schema, options = substitute_template_values(endpoint_name, request_type, options) if request_type && options && !schemas.empty?

      if options[:object_id]
        request_url = (custom_schema && !custom_schema.empty?) ? url(custom_schema) : url("/#{endpoint_name.to_s}/#{options[:object_id]}")
      else
        request_url = (custom_schema && !custom_schema.empty?) ? url(custom_schema) : url("/#{endpoint_name.to_s}")
      end

      if options[:extension]
        request_url = "#{request_url}.#{options[:extension]}"
      elsif self.extension
        request_url = "#{request_url}.#{self.extension}"
      end

      return request_url, options
    end

    def url(endpoint=nil)
      ssl? ? URI::HTTPS.build(host: @uri, path: endpoint) : URI::HTTP.build(host: @uri, path: endpoint)
    end
  end
end