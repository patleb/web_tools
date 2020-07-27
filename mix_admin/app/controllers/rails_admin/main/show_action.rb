module RailsAdmin::Main
  module ShowAction
    def show
      respond_to do |format|
        format.json { render json: @object }
        format.html { render :show }
      end
    end
  end
end
