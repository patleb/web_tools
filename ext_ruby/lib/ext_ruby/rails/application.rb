Rails::Application.class_eval do
  def name
    @_name ||= engine_name.delete_suffix('_application')
  end
end
