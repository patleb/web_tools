Rails::Application.class_eval do
  def name
    @_name ||= engine_name.delete_suffix('_application')
  end
end

module Rails
  def self.app
    @_app ||= ActiveSupport::StringInquirer.new(ENV["RAILS_APP"].presence || ENV["RACK_APP"].presence || application.name)
  end

  def self.app=(application)
    @_app = ActiveSupport::StringInquirer.new(application)
  end
end
