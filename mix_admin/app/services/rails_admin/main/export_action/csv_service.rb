# encoding: UTF-8
require 'csv'

module RailsAdmin::Main::ExportAction
  class CsvService < ActionService::Base[:@model, :@abstract_model, :@objects, :@schema]
    # https://medium.com/table-xi/stream-csv-files-in-rails-because-you-can-46c212159ab7
    # gzip option https://datamakessense.com/stream-gzip-with-ruby/
    def to_csv(options)
      @methods = [(@schema[:only] || []) + (@schema[:methods] || [])].flatten.compact
      @fields = @methods.map{ |m| export_fields_for(m, @model).first }
      @empty = I18n.t('admin.export.empty_value_for_associated_objects')
      schema_include = @schema.delete(:include) || {}

      @associations = schema_include.each_with_object({}) do |(name, values), hash|
        association = association_for(name, @model)
        association_methods = [(values[:only] || []) + (values[:methods] || [])].flatten.compact
        association_model = association.associated_model

        hash[name] = {
          association: association,
          fields: association_methods.map{ |m| export_fields_for(m, association_model).first },
        }
      end

      if (estimate = @objects.count_estimate) > RailsAdmin.config.export_max_rows
        raise RailsAdmin::TooManyRows.new("Too many rows: #{estimate} (max: #{RailsAdmin.config.export_max_rows})")
      end

      encoding_to = Encoding.find(options[:encoding_to]) if options[:encoding_to].present?

      csv_string = generate_csv_string(options)
      if encoding_to
        csv_string = csv_string.encode(encoding_to, invalid: :replace, undef: :replace, replace: '?')
      end

      # Add a BOM for utf8 encodings, helps with utf8 auto-detect for some versions of Excel.
      # Don't add if utf8 but user don't want to touch input encoding:
      # If user chooses utf8, they will open it in utf8 and BOM will disappear at reading.
      # But that way "English" users who don't bother and chooses to let utf8 by default won't get BOM added
      # and will not see it if Excel opens the file with a different encoding.
      csv_string = "\xEF\xBB\xBF#{csv_string}" if encoding_to == Encoding::UTF_8

      [!options[:skip_header], (encoding_to || csv_string.encoding).to_s, csv_string]
    end

  private

    def association_for(name, model)
      export_fields_for(name, model).find(&:association?)
    end

    def export_fields_for(method, model)
      fields = model.export.visible_fields.select { |f| f.name == method }
      @force_quotes ||= fields.any?(&:array?)
      fields
    end

    def generate_csv_string(options)
      generator_options = (options[:generator] || {}).delete_if{ |_, value| value.blank? }.with_keyword_access
      # TODO https://github.com/Paxa/light_record
      method = @objects.respond_to?(:find_each) ? :find_each : :each

      Parallel.map([options], in_processes: 1) do |options|
        CSV.generate(force_quotes: @force_quotes, **generator_options) do |csv|
          csv << generate_csv_header unless options[:skip_header] || @fields.nil?

          @objects.send(method) do |object|
            csv << generate_csv_row(object)
          end
        end
      end.first
    end

    def generate_csv_header
      @fields.map do |field|
        I18n.t('admin.export.csv.header_for_root_methods', name: field.label, model: @abstract_model.pretty_name)
      end +
        @associations.flat_map do |_association_name, option_hash|
          option_hash[:fields].map do |field|
            I18n.t('admin.export.csv.header_for_association_methods', name: field.label, association: option_hash[:association].label)
          end
        end
    end

    def generate_csv_row(object)
      @fields.map do |field|
        field.with(object: object).export_value_or_blank
      end +
        @associations.flat_map do |association_name, option_hash|
          associated_objects = [object.send(association_name)].flatten.compact
          option_hash[:fields].map do |field|
            associated_objects.map{ |ao| field.with(object: ao).export_value.presence || @empty }.join(',')
          end
        end
    end
  end
end
