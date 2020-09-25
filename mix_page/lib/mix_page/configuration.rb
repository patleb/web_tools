module MixPage
  has_config do
    attr_writer :parent_controller
    attr_writer :reserved_words
    attr_writer :layout
    attr_writer :available_layouts
    attr_writer :available_templates
    attr_writer :available_field_types
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

    def layout
      raise "unavailable layout: [#{@layout}]" unless available_layouts.has_key? @layout
      @layout
    end

    def available_layouts
      @available_layouts ||= {
        'layouts/pages' => 0
      }
    end

    def available_templates
      @available_templates ||= {}
    end

    def available_field_types
      @available_field_types ||= {
        'PageFields::Text' => 0,
        'PageFields::RichText' => 10,
        'PageFields::Link' => 20,
      }
    end

    def available_field_names
      @available_field_names ||= {}
    end

    def available_fieldables
      @available_fieldables ||= {
        'PageTemplate' => 0
      }
    end
  end
end
