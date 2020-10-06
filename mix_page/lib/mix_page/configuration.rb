module MixPage
  has_config do
    attr_writer   :js_routes
    attr_writer   :reserved_words
    attr_writer   :parent_controller
    attr_accessor :root_path
    attr_writer   :root_template
    attr_writer   :layout
    attr_writer   :available_layouts
    attr_writer   :available_templates
    attr_writer   :available_field_types
    attr_writer   :available_field_names
    attr_writer   :available_fieldables

    def js_routes
      @js_routes ||= MixPage.js_routes
    end

    def reserved_words
      @reserved_words ||= Set.new([MixPage::URL_SEGMENT, RailsAdmin.root_path.split('/').reject(&:blank?).first]).merge(%w(
        admin users javascript_rescues assets packs stylesheets javascripts images new edit index session login logout
      ))
    end

    def parent_controller
      @parent_controller ||= 'TemplatesController'
    end

    def root_template
      return unless @root_template
      raise "unavailable template: [#{@root_template}]" unless available_templates.has_key? @root_template
      raise "non-unique template: [#{@root_template}]" if @root_template.end_with? MixPage::MULTI_VIEW
      @root_template
    end

    def layout
      @layout ||= 'application'
      raise "unavailable layout: [#{@layout}]" unless available_layouts.has_key? @layout
      @layout
    end

    def available_layouts
      @available_layouts ||= {
        'application' => 0
      }
    end

    def available_templates
      @available_templates ||= {}
    end

    def available_field_types
      @available_field_types ||= {
        'PageFields::Text' => 0,
        'PageFields::Link' => 20,
        'PageFields::RichText' => 10,
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
