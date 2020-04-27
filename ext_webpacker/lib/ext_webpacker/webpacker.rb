require "ext_ruby"
require "ext_webpacker/gems"
require "webpacker"

ExtWebpacker::Gems.install

class Webpacker::Env
  private

  def fallback_env_warning
    # logger.info "RAILS_ENV=#{Rails.env} environment is not defined in config/webpacker.yml, falling back to #{DEFAULT} environment"
  end
end
