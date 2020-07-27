module RailsAdmin::Main
  module RestoreAction
    def restore
      if params[:bulk_ids].present? && (@objects = get_objects).present?
        processed = @objects.map(&:undiscard)

        if (restored = processed.select(&:to_b).size) > 0
          flash[:success] = success_notice(@model.pluralize(restored))
        end
        if (not_restored = processed.size - restored) > 0
          flash[:error] = error_notice(@model.pluralize(not_restored))
          redirect_to_back
        else
          redirect_to_index
        end
      else
        flash[:error] = error_notice(@model.pluralize(0))
        redirect_to_index
      end
    end
  end
end
