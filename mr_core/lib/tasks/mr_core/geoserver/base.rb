module Geoserver
  class Base < ActiveTask::Base
    class Failed < ::StandardError; end

    protected

    def get(path, params = nil)
      send_request(:get, path, nil, params)
    end

    def delete(path, params = nil)
      send_request(:delete, path, nil, params)
    end

    def put(path, data, params = nil)
      send_request(:put, path, data, params)
    end

    def post(path, data, params = nil)
      send_request(:post, path, data, params)
    end

    def post_sld(path, data, params = nil)
      @response = client.headers(content_type: 'application/vnd.ogc.sld+xml').post("#{base_url}/#{path}", params: params, body: data)
      handle_error unless @response.status.success?
      @response
    end

    def send_request(method, path, data, params)
      @response = client.send(method, "#{base_url}/#{path}", params: params, json: data)
      handle_error unless @response.status.success?
      @response
    end

    def handle_error
      unless error_message.include? 'already exists'
        puts "[#{@response.status.code}][#{@response.uri}] #{error_message.red}"
        raise Failed
      end
    end

    def client
      @client ||= HTTP.basic_auth(user: Setting[:geoserver_username], pass: Setting[:geoserver_password]).headers(accept: 'application/json')
    end

    def base_url
      @base_url ||= "#{Setting[:geoserver_local_url]}/rest"
    end

    def response_data
      ActiveSupport::JSON.decode(@response.to_s)
    end

    def error_message
      (Nokogiri::HTML(@response.to_s).xpath("//body/p/b[text()='Message']/../text()[1]").text.presence || @response.to_s).strip
    end
  end
end
