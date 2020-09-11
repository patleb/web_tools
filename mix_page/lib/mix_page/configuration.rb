module MixPage
  has_config do
    attr_writer :parent_controller
    attr_writer :reserved_words
    attr_writer :available_layouts
    attr_writer :available_templates
    attr_writer :available_fields
    attr_writer :available_field_names
    attr_writer :available_fieldables

    def parent_controller
      @parent_controller ||= '::ActionController::Base'
    end

    def reserved_words
      @reserved_words ||= Set.new([MixPage::URL_SEGMENT, RailsAdmin.root_path.split('/').reject(&:blank?).first]).merge(%w(
        admin users javascript_rescues assets packs stylesheets javascripts images new edit index session login logout
      ))
    end

    def available_layouts
      @available_layouts ||= {
        'layouts/pages' => 0
      }
    end

    def available_templates
      @available_templates ||= {}
    end

    def available_fields
      @available_fields ||= {
        'PageFieldText' => 10,
      }
    end

    def available_field_names
      @available_field_names ||= {}
    end

    def available_fieldables
      @available_fieldables ||= {}
    end
  end
end
