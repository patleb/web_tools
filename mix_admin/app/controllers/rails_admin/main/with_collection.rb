module RailsAdmin::Main::WithCollection # TODO https://github.com/jcypret/hashid-rails
  def get_objects
    scope = @abstract_model.scoped
    if (auth_scope = policy_scope(@abstract_model))
      scope = scope.merge(auth_scope)
    end
    section = @model.index
    fields = section.visible_fields # TODO use select(&:index_visible?) - removed if there is no filters + query
    eager_load = fields.select{ |f| f.respond_to?(:eager_load?) && f.eager_load? }.map{ |f| f.property.name }
    left_joins = fields.select{ |f| f.respond_to?(:left_joins?) && f.left_joins? }.map{ |f| f.property.name }
    options = {}
    options.merge!(include: eager_load) unless eager_load.empty?
    options.merge!(left_join: left_joins) unless left_joins.empty?
    options.merge!(distinct: true) if fields.any?{ |f| f.respond_to?(:distinct?) && f.distinct? }
    options.merge!(get_sort_hash(section, fields))
    options.merge!(get_page_hash(section, options[:sort])) if !(params[:all] || params[:bulk_ids])
    options.merge!(query: params[:query]) if params[:query].present?
    options.merge!(filters: params[:f]) if params[:f].present?
    options.merge!(bulk_ids: params[:bulk_ids]) if params[:bulk_ids]
    @abstract_model.all(scope, options)
  end

  private

  def get_sort_hash(section, fields)
    unless (field = fields.find{ |f| f.name.to_s == params[:sort] })
      params[:sort] = params[:reverse] = nil
    end
    no_sort = params[:sort].nil?
    params[:sort] ||= section.sort_by.to_s

    column = begin
      if field.nil? || (sortable = field.sortable) == true # use params[:sort] on the base table
        params[:sort]&.include?('.') ? params[:sort] : %{"#{@abstract_model.table_name}"."#{params[:sort]}"}
      elsif sortable == false # use default sort, asked field is not sortable
        %{"#{@abstract_model.table_name}"."#{section.sort_by}"}
      elsif (sortable.is_a?(String) || sortable.is_a?(Symbol)) && sortable.to_s.include?('.') # just provide sortable, don't do anything smart
        sortable.to_s
      elsif sortable.is_a?(Hash) # just join sortable hash, don't do anything smart
        %{"#{sortable.first.join('"."')}"}
      elsif field.association? # use column on target table
        %{"#{field.associated_model.abstract_model.table_name}"."#{sortable}"}
      else # use described column in the field conf.
        %{"#{@abstract_model.table_name}"."#{sortable}"}
      end
    end

    params[:reverse] = (field ? field.sort_reverse? : section.sort_reverse?) if no_sort
    { sort: column, reverse: params[:reverse].to_b }
  end

  def get_page_hash(section, sort)
    page = (params[:page] || 1).to_i
    if params[:first].present?
      sort = sort.delete_prefix(%{"#{@abstract_model.table_name}"."}).chop
      if section.sort_paginate.include? sort.to_sym
        first = params[:first]
      end
    end
    per_choices = [section.items_per_page, section.max_items_per_page]
    per = per_choices.include?(paginate_per) ? paginate_per : per_choices.first
    { page: page, per: per, first: first }
  end

  def paginate_per
    @_paginate_per ||= model_cookie[:per].to_i
  end
end
