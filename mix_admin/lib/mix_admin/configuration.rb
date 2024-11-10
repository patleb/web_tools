module MixAdmin
  has_config do
    attr_writer :root
    attr_writer :main_app_name
    attr_writer :memoize_models_menu
    attr_writer :navigation_static_links
    attr_writer :root_model_name
    attr_writer :record_label_methods
    attr_writer :included_models
    attr_writer :excluded_models
    attr_writer :actions
    attr_writer :viewable_actions
    attr_writer :sticky
    attr_writer :items_per_page
    attr_writer :shortcuts
    attr_writer :field_aliases
    attr_writer :hidden_fields
    attr_writer :denied_fields
    attr_writer :readonly_fields
    attr_writer :confirm_delete
    attr_writer :simplify_search_string
    attr_accessor :full_query_column

    def root_path
      @root_path ||= "/#{root.to_s.delete_prefix('/').delete_suffix('/')}"
    end

    def root
      @root ||= '/model'
    end

    def main_app_name
      @main_app_name ||= proc{ Rails.application.title }
    end

    def memoize_models_menu
      return @memoize_models_menu if defined? @memoize_models_menu
      @memoize_models_menu = true
    end

    def navigation_static_links
      @navigation_static_links ||= {
        'Markdown' => 'https://www.markdownguide.org/cheat-sheet/'
      }
    end

    def root_model_name
      @root_model_name ||= 'User'
    end

    def record_label_methods
      @record_label_methods ||= []
    end

    def models_pool
      @models_pool ||= SortedSet.new(expand_models(included_models) - expand_models(excluded_models))
    end

    def included_models
      @included_models ||= []
    end

    def excluded_models
      @excluded_models ||= []
    end

    def actions
      @action ||= Set.new(%i(
        index
        export
        show
        edit
        new
        delete
        trash
        restore
      ))
    end

    def viewable_actions
      @viewable_actions ||= Set.new(%i(
        show
        edit
      ))
    end

    def sticky
      return @sticky if defined? @sticky
      @sticky = true
    end

    def items_per_page
      @items_per_page ||= GearedPagination::Ratios::DEFAULTS
    end

    def shortcuts
      @shortcuts ||= { left: 1, window: 0, right: 0 }
    end

    def field_aliases
      @field_aliases ||= {
        big_integer: :integer,
        citext: :string,
        datetime: :date_time,
        float: :decimal,
        has_and_belongs_to_many: :has_many,
        int8range: :integer,
        inet: :string,
        jsonb: :json,
        ltree: :string,
        numrange: :decimal,
        tsrange: :timestamp,
      }
    end

    def hidden_fields
      @hidden_fields ||= Set.new([:lock_version])
    end

    def denied_fields
      @denied_fields ||= Set.new([:json_data, :deleted_at, :creator_id, :updater_id, :parent_id, :position])
    end

    def readonly_fields
      @readonly_fields ||= Set.new([:id, :created_at, :updated_at, :creator, :updater, :parent])
    end

    def confirm_delete
      return @confirm_delete if defined? @confirm_delete
      @confirm_delete = true
    end

    def simplify_search_string
      return @simplify_search_string if defined? @simplify_search_string
      @simplify_search_string = true
    end

    private

    def expand_models(list)
      list.flat_map do |name|
        name = name.to_s
        if name.include? '%'
          name = "^#{name}" if name.start_with? '%'
          name = "#{name}$" if name.end_with? '%'
          regex = /#{name.gsub('%', '.*')}/
          ActiveRecord::Base.viable_models.select(&:match?.with(regex))
        else
          name
        end
      end
    end
  end
end
