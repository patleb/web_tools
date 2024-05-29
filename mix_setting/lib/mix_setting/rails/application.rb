Rails::Application.class_eval do
  def credentials
    Setting
  end
end
