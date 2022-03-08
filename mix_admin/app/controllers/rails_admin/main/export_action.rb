module RailsAdmin::Main
  module ExportAction
    def export
      if request.format.html?
        render :export
      elsif export_schema
        @schema = export_schema
        set_index_objects

        respond_to do |format|
          format.json.file do
            json = without_time_zone{ @objects.to_json(@schema) }
            send_data json, filename: "#{params[:model_name]}_#{Time.current.strftime('%Y-%m-%d_%Hh%Mm%S')}.json"
          end
          format.json.none { render json: without_time_zone{ @objects.to_json(@schema) } }

          # TODO xml doesn't work
          format.xml.file do
            xml = without_time_zone{ @objects.to_xml(@schema) }
            send_data xml, filename: "#{params[:model_name]}_#{Time.current.strftime('%Y-%m-%d_%Hh%Mm%S')}.xml"
          end
          format.xml.none { render xml: without_time_zone{ @objects.to_xml(@schema) } }

          # TODO https://github.com/rails/rails/pull/41488
          format.csv do |variant|
            options = params[:csv_options].permit(:encoding_to, :skip_header, generator: [:col_sep])
            header, encoding, csv = without_time_zone{ CsvService.new.to_csv(options) }
            variant.file do
              send_data csv,
                type: "text/csv; charset=#{encoding}; #{'header=present' if header}",
                disposition: "attachment; filename=#{params[:model_name]}_#{Time.current.strftime('%Y-%m-%d_%Hh%Mm%S')}.csv"
            end
            variant.none do
              # TODO https://coderwall.com/p/kad56a/streaming-large-data-responses-with-rails
              # https://medium.com/table-xi/stream-csv-files-in-rails-because-you-can-46c212159ab7
              # http://smsohan.com/blog/2013/05/09/genereating-and-streaming-potentially-large-csv-files-using-ruby-on-rails/
              render plain: output
            end
          end
        end
      else
        head :no_content
      end
    end

    def export_action?
      main_action.export?
    end

    private

    def export_schema
      return unless params[:schema] # to_json and to_xml expect symbols for keys AND values.
      @_export_schema ||= params.require(:schema).to_unsafe_h.slice(:except, :include, :methods, :only).full_symbolize
    end
  end
end
