require "httparty"
require "json"
require "openssl"

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

    def albums
      handle_response self.class.get("/")
    end

    def photos(album_id, options = {})
      handle_response self.class.get("/albums/#{album_id}", :query => options)
    end

    def photo(album_id, photo_id, options = {})
      handle_response self.class.get("/albums/#{album_id}/photos/#{photo_id}", :query => options)
    end

    def tags(album_id, tag, options = {})
      handle_response self.class.get("/albums/#{album_id}/tag/#{tag}", :query => options)
    end

    def tag_counts(album_id, options = {})
      handle_response self.class.get("/albums/#{album_id}/tag_counts", :query => options)
    end

    def create_photo(album_id, media, options = {})
      media   = {:media => media}.merge(options)
      payload = signed_data(media).to_json

      puts payload

      handle_response self.class.post("/albums/#{album_id}/photos", :body => payload, :headers => { 'Content-Type' => 'application/json' })
    end

    # Legacy support
    alias_method :get_albums, :albums
    alias_method :get_album_contents, :photos 
    alias_method :get_album_photo, :photo

    private
    def signed_data(data)
      {
        :data      => data,
        :api_key   => @api_key,
        :signature => OpenSSL::HMAC.hexdigest('sha256', @api_secret, data.to_json)
      }
    end

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