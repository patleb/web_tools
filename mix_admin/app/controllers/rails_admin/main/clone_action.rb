module RailsAdmin::Main
  module CloneAction
    def clone
      respond_to do |format|
        format.html { render :clone }
      end
    end
  end
end
