module RailsAdmin::Config::Model::Fields::Date::Formatter
  extend ActiveSupport::Concern

  included do
    register_instance_option :i18n_scope do
      [:date, :formats, :pretty]
    end
  end
end
