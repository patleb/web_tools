require 'rack/utils'

module Rack::Utils
  SESSION_ID = /\A[\da-f]{32}\z/.freeze

  def merge_url(url, params = {}, scheme: nil, hostname: nil, port: nil, path: nil)
    uri, query_params = parse_url(url)
    query_params.merge!(params)
    query      = "?#{query_params.to_param}" unless query_params.empty?
    scheme   ||= uri.scheme
    hostname ||= uri.hostname
    port     ||= uri.port
    port       = nil if [80, 443].include? port
    path     ||= uri.path

    [scheme, '://', hostname, (':' if port), port, ('/' unless path.start_with? '/'), path, query].join
  end
  module_function :merge_url

  def parse_params(url)
    parse_url(url).last
  end
  module_function :parse_params

  def parse_url(url)
    uri = URI.parse(url)
    params = parse_nested_query(uri.query).with_indifferent_access

    [uri, params]
  end
  module_function :parse_url

  def add_status_code(code, message)
    HTTP_STATUS_CODES[code] = message
    SYMBOL_TO_STATUS_CODE[message.downcase.gsub(/\s|-|'/, '_').to_sym] = code
  end
  module_function :add_status_code

  def status_reason(code)
    HTTP_STATUS_CODES[code] || 'Internal Server Error'
  end
  module_function :status_reason
end
