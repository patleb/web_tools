require "ext_ruby"
require "ext_webpacker/gems"
require "webpacker"

Webpacker::Env.class_eval do
  private

  def fallback_env_warning
    # logger.info "RAILS_ENV=#{Rails.env} environment is not defined in config/webpacker.yml, falling back to #{DEFAULT} environment"
  end
end

ExtWebpacker::Gems.install
