module RailsAdmin::Main
  module TrashAction
    extend ActiveSupport::Concern

    included do
      helper_method :trash_action?
    end

    def trash
      params.delete(:scope)
      @objects = get_objects.only_discarded
      set_index_objects

      respond_to do |format|
        format.html.more { render :trash, layout: false }
        format.html.none { render :trash, status: @status_code || :ok }
      end
    end

    def trash_action?
      main_action.trash?
    end
  end
end
