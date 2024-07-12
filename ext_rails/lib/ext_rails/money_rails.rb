require "money-rails"

module MoneyRails
  def self.with_currency(currency)
    old_currency = Money.default_currency
    MoneyRails.default_currency = currency if currency
    yield
  ensure
    MoneyRails.default_currency = old_currency
  end
end
