require 'money-rails/helpers/action_view_extension'

class RailsAdmin::Config::Model::Fields::OdooMoney < RailsAdmin::Config::Model::Fields::Decimal
  include MoneyRails::ActionViewExtension

  register_instance_option :pretty_value do
    humanized_money_with_symbol(value)
  end
end
