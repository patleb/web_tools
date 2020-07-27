module RailsAdmin::Config::Model::Fields::Timestamp::Formatter
  extend ActiveSupport::Concern

  included do
    register_instance_option :i18n_scope do
      [:timestamp, :formats, :pretty]
    end
  end
end
