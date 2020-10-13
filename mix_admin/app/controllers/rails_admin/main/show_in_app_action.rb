module RailsAdmin::Main
  module ShowInAppAction
    def show_in_app
      redirect_to(@object.try(:to_url) || main_app.url_for(@object))
    end
  end
end
