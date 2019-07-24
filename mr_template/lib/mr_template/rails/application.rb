Rails::Application.class_eval do
  def title
    @_title ||= name.titleize
  end
end
