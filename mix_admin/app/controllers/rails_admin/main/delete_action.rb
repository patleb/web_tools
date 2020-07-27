module RailsAdmin::Main
  module DeleteAction
    def delete
      if request.get? # DELETE
        render :delete
      elsif request.put? || request.delete? # DISCARD, DESTROY
        delete_method, delete_action = delete_method_and_action

        if @object.public_send(delete_method)
          flash[:success] = success_notice(action: delete_action)
          redirect_to_index
        else
          flash[:error] = error_notice(action: delete_action)
          redirect_to_back
        end
      end
    end

    def delete_method_and_action
      if request.put?
        [:discard, 'trash']
      elsif request.delete?
        [:destroy, 'delete']
      end
    end
  end
end
