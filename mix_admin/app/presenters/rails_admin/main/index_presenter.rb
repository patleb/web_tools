# TODO identity_cache admin side
# TODO application side --> https://github.com/Shopify/cacheable
# --> custom solution would be beneficial by reusing mobility for search functionality
module RailsAdmin::Main
  class IndexPresenter < BasePresenter
    def after_initialize
      initialize_table_presenters
    end
  end
end
