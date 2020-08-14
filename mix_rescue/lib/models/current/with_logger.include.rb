module Current::WithLogger
  extend ActiveSupport::Concern

  included do
    attribute :error_logged
  end
end
