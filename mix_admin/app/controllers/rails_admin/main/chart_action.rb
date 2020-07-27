module RailsAdmin::Main
  module ChartAction
    def chart
      respond_to do |format|
        format.html.chart do
          set_index_objects
          render :chart
        end
        format.html.none { render :chart }
        format.json.chart do
          set_index_objects
          charts = ChartService.new.extract_charts
          render json: charts
        end
      end
    end

    def chart_action?
      main_action.chart?
    end
  end
end
