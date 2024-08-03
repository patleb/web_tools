require "ext_ruby"
require "ext_shakapacker/shakapacker/with_gems"
require "shakapacker"

Shakapacker::Env.class_eval do
  private

  def fallback_env_warning
    # logger.info "RAILS_ENV=#{Rails.env} environment is not defined in config/shakapacker.yml, falling back to #{DEFAULT} environment"
  end
end

Shakapacker::BaseStrategy.class_eval do
  class_attribute :gems_watched_paths # :watched_paths is deprecated

  private

  alias_method :old_default_watched_paths, :default_watched_paths
  def default_watched_paths
    (gems_watched_paths + old_default_watched_paths).freeze
  end
end

module Shakapacker
  extend self::WithGems
end

Shakapacker.install
