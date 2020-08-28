module MixPage
  has_config do
    attr_writer :parent_controller
    attr_writer :reserved_words
    attr_writer :available_layouts
    attr_writer :available_templates
    attr_writer :available_fields
    attr_writer :available_field_keys
    attr_writer :available_fieldables

    def parent_controller
      @parent_controller ||= '::ActionController::Base'
    end

    def reserved_words
      @reserved_words ||= Set.new(%w(
        new edit index session login logout users admin assets packs stylesheets javascripts images
      ))
    end

    def available_layouts
      @available_layouts ||= {
        'layouts/pages' => 0
      }
    end

    def available_templates
      @available_templates ||= {
        'pages/home' => 0,
      }
    end

    def available_fields
      @available_fields ||= {
        'PageField' => 0,
        'PageField::Text' => 10,
      }
    end

    def available_field_keys
      @available_field_keys ||= {}
    end

    def available_fieldables
      @available_fieldables ||= {}
    end
  end
end
