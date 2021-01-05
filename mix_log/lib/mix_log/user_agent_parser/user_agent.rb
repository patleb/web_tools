UserAgentParser::UserAgent.class_eval do
  def browser
    browser = to_h
    browser[:os][:version] = browser.dig(:os, :version, :version)&.delete_suffix('.')
    browser[:version] = browser.dig(:version, :version)&.delete_suffix('.')
    browser.deep_transform_values!{ |v| v == 'Other' ? nil : v }
    device = browser.delete(:device)
    case device[:family]
    when [device[:brand], device[:model]].join(' '), device[:model], device[:brand]
      device.delete(:family)
    end
    browser[:hw] = device.values_at(:brand, :model).compact.uniq
    browser[:os] = browser[:os].values_at(:family, :version).compact
    browser[:v] = browser.delete(:version)
    browser[:name] = browser.delete(:family)
    browser.reject!{ |_, v| v.blank? }
    browser
  end
end
