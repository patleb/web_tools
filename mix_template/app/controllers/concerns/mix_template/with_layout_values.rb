module MixTemplate
  module WithLayoutValues
    extend ActiveSupport::Concern

    prepended do
      before_action :set_root_path
      before_render :set_layout_values
    end

    private

    def set_root_path
      @root_path = respond_to?(:root_path) ? root_path : '/'
    end

    def set_layout_values
      @app_name = @page_title = @page_description = Rails.application.title
    end
  end
end
