module RailsAdmin::Config::Model::Fields::Time::Formatter
  extend ActiveSupport::Concern

  included do
    register_instance_option :i18n_scope do
      [:time, :formats, :pretty]
    end
  end
end
