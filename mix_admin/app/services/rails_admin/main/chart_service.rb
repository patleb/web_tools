module RailsAdmin::Main
  class ChartService < ActionService::Base[:@model, :@abstract_model, :@objects]
    # TODO duplicate fields when fields added
    def extract_charts
      # TODO deny refresh=true for request longer than 1 day
      # TODO deny request longer than 1 week and 1 day
      if (estimate = @objects.count_estimate) > RailsAdmin.config.chart_max_rows
        raise RailsAdmin::TooManyRows.new("Too many rows: #{estimate} (max: #{RailsAdmin.config.chart_max_rows})")
      elsif estimate == 0
        return []
      end

      charts =
        if params.has_key? :c
          params[:c].to_unsafe_h.each_with_object([]) do |(_index, chart_form), forms|
            forms << [chart_form[:field], chart_form[:calculation]]
          end
        elsif params.has_key? :chart_form
          chart_form = params[:chart_form]
          [[chart_form[:field], chart_form[:calculation]]]
        else
          []
        end

      charts.map! do |(field, calculation)|
        return unless prepare(field, calculation)
        execute
      end

      assign_right_y_axis(charts)
      charts
    end

    private

    def prepare(field, calculation)
      @calculation = calculation.try(:to_sym)

      field_param = Rack::Utils.parse_nested_query(field).with_keyword_access
      schema = field_param[:schema].slice(:except, :include, :methods, :only).to_h.full_symbolize

      return unless (method = schema[:only] || schema[:methods])
      method = method.first[0]
      @field = chart_field_for(method, @model).first
      @section = @model.chart.with(chart_field: method)
      schema_include = schema.delete(:include) || {}
      name, values = schema_include.first

      return if @field || name.nil?

      association = association_for(name, @model)
      association_method = (values[:only] || values[:methods]).first[0]
      association_model = association.associated_model

      @association = { name => {
        abstract_model: association_model.abstract_model,
        field: chart_field_for(association_method, association_model).first,
        section: association_model.chart
      } }
    end

    def execute
      query = @objects
      if @field && @section.group_by
        query = run_query(query)
        query = map_query_values(query)
      elsif @association
        association_name, _option_hash = @association.first
        query = query.include(association_name)
      end
      { name: "#{@field.label} - #{@calculation}", data: query }
    end

    def assign_right_y_axis(charts)
      maxes = charts.map do |chart|
        chart[:data].max_by{ |item| item.last&.abs }.last&.abs
      end
      max = maxes.compact.max
      smaller_max = max ? max / @section.y2_ratio : 0

      charts.each_with_index do |chart, i|
        max = maxes[i]
        if max.nil? || max < smaller_max
          chart[:y2] = true
        end
      end
    end

    def association_for(name, model)
      chart_field_for(name, model).find(&:association?)
    end

    def chart_field_for(method, model)
      model.chart.visible_fields.select{ |f| f.name == method }
    end

    def run_query(query)
      group_by = @section.group_by

      group_base, group_name = automatic_resolution(query, group_by)
      query = query.reorder(nil).group(group_base).order(group_name)

      field_name = @field.name
      model, select_method = @abstract_model.klass, "chart_#{field_name}"
      if model.respond_to? select_method
        field_name = model.send select_method
      end

      if (work_mem = @section.work_mem)
        model.with_setting("#{work_mem}MB") do
          query.send(@calculation, field_name)
        end
      else
        query.send(@calculation, field_name)
      end
    end

    def automatic_resolution(query, group_by)
      group_by = group_by.to_s.split('.').last
      first, last = query.first.send(group_by), query.last.send(group_by)
      first, last = last, first if first > last
      seconds = (last - first).to_i
      chunk_size = (seconds / @section.max_size.to_f).ceil
      chunk_size = 1 if chunk_size == 0 # TODO do not make any request

      [<<~SQL, "to_timestamp_floor_extract_epoch_from_#{group_by}_#{chunk_size}_all_#{chunk_size}_at_time_zone_utc"[0..62]]
        to_timestamp(FLOOR((EXTRACT('epoch' FROM #{group_by}) / #{chunk_size} )) * #{chunk_size}) AT TIME ZONE 'UTC'
      SQL
    end

    def map_query_values(query)
      if (map = @section.map)
        query =
          if map.is_a? Proc
            query.map(&map)
          else
            method, *args = Array.wrap(map)
            query.map do |group_by_value|
              group_by_value[1] = group_by_value[1].send(method, *args)
              group_by_value
            end
        end
      end
      query
    end
  end
end
