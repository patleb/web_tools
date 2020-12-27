UserAgentParser::UserAgent.class_eval do
  def browser
    browser = to_h
    browser[:os][:version] = browser.dig(:os, :version, :version)&.delete_suffix('.')
    browser[:version] = browser.dig(:version, :version)&.delete_suffix('.')
    browser.deep_transform_values!{ |v| v == 'Other' ? nil : v }
    browser[:device].compact!
    browser[:os].compact!
    browser.compact!
    browser
  end
end
