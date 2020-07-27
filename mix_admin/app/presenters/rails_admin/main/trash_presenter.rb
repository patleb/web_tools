module RailsAdmin::Main
  class TrashPresenter < BasePresenter
    def after_initialize
      initialize_table_presenters
    end
  end
end
