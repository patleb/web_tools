require "ext_ruby"
require "ext_webpacker/gems"
require "webpacker"

Webpacker::Env.class_eval do
  private

  def fallback_env_warning
    # logger.info "RAILS_ENV=#{Rails.env} environment is not defined in config/webpacker.yml, falling back to #{DEFAULT} environment"
  end
end

Webpacker::Compiler.class_eval do
  class_attribute :gems_watched_paths

  private

  alias_method :old_default_watched_paths, :default_watched_paths
  def default_watched_paths
    (gems_watched_paths + old_default_watched_paths).freeze
  end
end

ExtWebpacker::Gems.install
