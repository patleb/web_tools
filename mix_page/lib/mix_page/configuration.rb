module MixPage
  has_config do
    attr_writer   :js_routes
    attr_writer   :parent_controller
    attr_accessor :root_path
    attr_accessor :root_template
    attr_writer   :layout
    attr_writer   :available_layouts
    attr_writer   :available_templates
    attr_writer   :available_field_types
    attr_writer   :available_field_names
    attr_writer   :available_fieldables
    attr_writer   :member_actions
    attr_writer   :max_children_count
    attr_writer   :max_image_size
    attr_accessor :skip_sidebar_link

    def js_routes
      @js_routes ||= MixPage.routes
    end

    def parent_controller
      @parent_controller ||= 'TemplatesController'
    end

    def layout
      @layout ||= 'application'
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
        'PageFields::Text'     => 0,
        'PageFields::RichText' => 10,
        'PageFields::Link'     => 20,
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

    def member_actions
      @member_actions ||= %i(edit delete)
    end

    def max_image_size
      @max_image_size ||= 5.megabytes
    end

    def max_children_count
      @max_children_count || Float::INFINITY
    end
  end
end
