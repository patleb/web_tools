module RailsAdmin::Main
  module BulkDeleteAction
    def bulk_delete
      if request.post? || request.get? # BULK DELETE
        @objects = get_objects

        if @objects.blank?
          flash[:error] = error_notice(@model.pluralize(0), action: 'delete')
          redirect_to_index
        else
          render :bulk_delete
        end
      elsif request.put? || request.delete? # BULK DISCARD, BULK DESTROY
        delete_method, delete_action = delete_method_and_action
        if params[:bulk_ids].present? && (@objects = get_objects).present?
          processed = @objects.each(&delete_method)

          if (deleted = processed.select(&:"#{delete_method}ed?")).any?
            flash[:success] = success_notice(@model.pluralize(deleted.count), action: delete_action)
          end
          if (not_deleted = processed - deleted).any?
            flash[:error] = error_notice(@model.pluralize(not_deleted.count), action: delete_action)
            redirect_to_back
          else
            redirect_to_index
          end
        else
          flash[:error] = error_notice(@model.pluralize(0), action: delete_action)
          redirect_to_index
        end
      end
    end
  end
end
