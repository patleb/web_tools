class RailsAdmin::Config::Actions::Choose < RailsAdmin::Config::Actions::Base
  def collection?
    true
  end

  def http_methods
    [:post, :delete]
  end

  def allowed_sections
    %w(export chart).to_h
  end
end
