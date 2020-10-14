module RailsAdmin::Main
  module SortAction
    extend ActiveSupport::Concern

    included do
      helper_method :sort_action?
    end

    def sort
      if request.get?
        params.delete(:scope)
        @objects = get_objects
        set_index_objects

        respond_to do |format|
          format.html.more { render :sort, layout: false }
          format.html.none { render :sort, status: @status_code || :ok }
        end
      elsif request.put?
        attributes = params.require(@abstract_model.param_key).permit(:id, :list_prev_id, :list_next_id)
        raise ObjectNotFound unless (@object = @abstract_model.get(attributes.delete(:id)))
        raise Pundit::NotAuthorizedError unless authorized? :edit, @abstract_model, @object

        if @object.update(attributes)
          respond_to do |format|
            format.json.inline do
              render json: { flash: { success: success_notice } }
            end
          end
        else
          handle_save_error :edit
        end
      end
    end

    def sort_action?
      main_action.sort?
    end
  end
end
