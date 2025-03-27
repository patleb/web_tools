module MixPage
  has_config do
    attr_accessor :root_path
    attr_writer   :root_template
    attr_writer   :layout
    attr_writer   :available_layouts
    attr_writer   :available_templates
    attr_writer   :available_field_types
    attr_writer   :available_field_names
    attr_writer   :permanent_field_names
    attr_writer   :available_fieldables
    attr_accessor :skip_sidebar
    attr_accessor :skip_content

    def root_template
      @root_template ||= 'home'
    end

    def layout
      @layout ||= 'pages'
    end

    def available_layouts
      @available_layouts ||= {
        'pages' => 10,
      }
    end

    def available_templates
      @available_templates ||= {
        'home' => 0,
      }
    end

    def available_field_types
      @available_field_types ||= {
        'PageFields::Text' => 0,
        'PageFields::Html' => 10,
        'PageFields::Link' => 20,
      }
    end

    def available_field_names
      @available_field_names ||= {
        sidebar: 0,
        content: 10,
      }
    end

    def permanent_field_names
      @permanent_field_names ||= Set.new(%i(
        sidebar
        content
      ))
    end

    def available_fieldables
      @available_fieldables ||= {
        'PageTemplate' => 0
      }
    end
  end
end
