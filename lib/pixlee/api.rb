require "httparty"

module Pixlee
  class API
    include HTTParty

    attr_reader :api_key, :api_secret, :user_id

    def initialize(api_key, api_secret, user_id)
      @api_key    = api_key.to_s.strip
      @api_secret = api_secret.to_s.strip
      @user_id    = user_id.to_s.strip

      if @api_key.empty? || @api_secret.empty? || @user_id.empty?
        raise Pixlee::Exception.new('An API key, API secret and app name are required')
      end

      self.class.base_uri "https://api.pixlee.com/v1/#{@user_id}"
      self.class.default_params[:api_key] = @api_key
    end

    def get_albums
      handle_response self.class.get("/")
    end

    private

    def handle_response(response)
      if !response.code.between?(200, 299)
        raise Pixlee::Exception.new("HTTP #{response.code} response from API")
      elsif response.parsed_response['status'].nil? || !response.parsed_response['status'].to_i.between?(200, 299)
        raise Pixlee::Exception.new("#{response.parsed_response['status']} - #{response.parsed_response['message']}")
      else
        response.parsed_response
      end
    end
  end
end