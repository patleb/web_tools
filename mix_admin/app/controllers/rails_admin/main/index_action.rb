module RailsAdmin::Main
  module IndexAction
    extend ActiveSupport::Concern

    included do
      helper_method :index_section, :index_fields, :index_scopes, :index_scope
    end

    def index
      set_index_objects

      respond_to do |format|
        format.html.more { render :index, layout: false }
        format.html.none { render :index, status: @status_code || :ok }
        format.json.compact do
          primary_key_method = @association ? @association.associated_primary_key : @model.abstract_model.primary_key
          output = @objects.map{ |o| { value: o.send(primary_key_method).to_s, text: @model.with(object: o).object_label.to_s } }
          render json: output, root: false
        end
      end
    end

    def set_index_objects
      @objects ||= get_objects

      unless request.variant.compact? || trash_action?
        if index_scope.nil?
          unless (scope = index_scopes.first).nil?
            @objects = @objects.public_send(scope)
          end
        elsif index_scopes.map(&:to_s).include? index_scope
          @objects = @objects.public_send(index_scope)
        end
      end

      if (included_columns = index_section.include_columns) && (excluded_columns = index_section.exclude_columns)
        included_columns -= excluded_columns
      end
      if included_columns
        included_columns << @model.abstract_model.primary_key.to_sym
        @objects = @objects.select(*included_columns.uniq)
      elsif excluded_columns
        @objects = @objects.select_without(*excluded_columns)
      end

      @objects = @objects.none unless index_section.exists?
    end

    def index_action?
      main_action.index?
    end

    def index_section
      @index_section ||= @model.index.with(objects: @objects)
    end

    def index_fields
      @index_fields ||= index_section.visible_fields
    end

    def index_scopes
      @index_scopes ||= index_section.scopes
    end

    def index_scope
      @index_scope ||= begin
        scope = params[:scope]
        scope = index_scopes.first || :nil if scope.blank? # TODO .nil? --> always false
        ActiveSupport::StringInquirer.new(scope.to_s)
      end
    end
  end
end