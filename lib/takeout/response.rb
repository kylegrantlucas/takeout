module Takeout
  class Response
    attr_accessor :headers
    attr_accessor :body
    attr_accessor :response
    attr_accessor :options

    def initialize(options={})
      if block_given?
        yield self
      else
        extract_instance_variables_from_options(options)
      end
    end

    def extract_instance_variables_from_options(options)
      # Set instance variables
      @headers = options[:headers] || ''
      @body = options[:body] || {}
      @response = options[:response] || {}


      # Clean instance variables out of options hash and set that as options instance variable
      [:headers, :body, :response].each { |v| options.delete(v) }
      @options = options
    end
  end
end