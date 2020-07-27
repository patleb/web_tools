module RailsAdmin::Main
  module BulkAction
    def bulk_action
      raise Pundit::NotAuthorizedError unless bulk_action?
      response.headers['X-PJAX-REDIRECT'] = bulk_url
      serve_action @bulk_action.to_sym
    end

    def bulk_action?
      return !!@bulk_action if defined? @bulk_action
      bulkables = RailsAdmin.actions(bulkable_type, @abstract_model).map(&:route_fragment)
      (@bulk_action = params[:js_bulk_action]).in? bulkables
    end

    def bulk_url
      RailsAdmin.url_for(action: @bulk_action, model_name: params[:model_name], bulk_ids: params[:bulk_ids])
    end

    def bulkable_type
      @bulkable_type ||= (params[:bulkable_type] || :bulkable).to_sym
    end
  end
end
