module TaskAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label_i18n_key :system
      navigation_weight 999

      configure :name do
        readonly true
        pretty_value{ value }
      end
      configure :description
      configure :parameters, :string_array do
        visible{ object&.arguments_visible? }
      end
      configure :arguments do
        visible{ object&.arguments_visible? }
      end
      configure :state do
        readonly true
      end
      configure :updated_at do
        readonly true
        visible true
      end
      configure :duration_avg
      configure :output, :code do
        readonly true
      end
      configure :notify do
        readonly{ !object.notify_editable? }
      end
      configure :_perform, :boolean do
        readonly{ object.running? }
      end

      include_fields :name, :description, :parameters, :arguments, :state, :updated_at, :duration_avg, :output, :updater, :notify, :_perform

      index do
        sort_by :name
        sort_reverse true
        exclude_fields :_perform
      end
    end
  end
end
