Rails::Application.class_eval do
  def credentials
    secrets
  end
end
