require "money"
require "monetize"
require "monetize/core_extensions"
require "money-rails/configuration"
require "money-rails/money"
require "money-rails/version"
require 'money-rails/hooks'
require 'money-rails/errors'

module MoneyRails
  extend Configuration

  def self.with_currency(currency)
    old_currency = Money.default_currency
    MoneyRails.default_currency = currency if currency
    yield
  ensure
    MoneyRails.default_currency = old_currency
  end
end

require "money-rails/railtie"
require "money-rails/engine"
