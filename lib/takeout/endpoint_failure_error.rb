module Takeout
  class EndpointFailureError < StandardError
    attr_reader :object, :request_type, :request_url, :response_code, :response

    def initialize(object, request_type)
      @object, @request_type = object, request_type
    end

    def initialize(object, request_type, response)
      @object, @request_type, @response = object, request_type, response
    end

    def message
      "Error in calling #{@request_type.to_s.upcase} on the endpoint: #{@object.url}, response_code: #{@object.response_code}"
    end
  end
end