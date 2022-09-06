module Current::WithTheme
  extend ActiveSupport::Concern

  included do
    attribute :theme

    alias_method :theme_without_default, :theme
    def theme
      theme_without_default || 'light'
    end
  end
end
