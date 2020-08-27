module MixPage
  has_config do
    attr_writer :parent_controller
    attr_writer :available_layouts
    attr_writer :available_templates
    attr_writer :available_fields
    attr_writer :available_fieldables
    attr_writer :reserved_words

    def parent_controller
      @parent_controller ||= '::ActionController::Base'
    end

    def available_layouts
      @available_layouts ||= {
        'layouts/pages' => 0
      }
    end

    def available_templates
      @available_templates ||= {
        'pages/home' => 0
      }
    end

    def available_fields
      @available_fields ||= {
        'PageField' => 0,
        'PageFieldText' => 10,
      }
    end

    def available_fieldables
      @available_fieldables ||= {}
    end

    def reserved_words
      @reserved_words ||= Set.new(%w(
        new edit index session login logout users admin assets packs stylesheets javascripts images
      ))
    end
  end
end
