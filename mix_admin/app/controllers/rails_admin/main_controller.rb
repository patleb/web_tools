module RailsAdmin
  class MainController < Config.parent_controller.constantize
    prepend_before_action :authenticate_user!
    protect_from_forgery Config.forgery_protection_settings

    include ActionView::Helpers::TextHelper
    include MrTemplate::WithPjax
    include MrTemplate::WithLayoutValues
    prepend Main::WithAuthorization
    include Main::WithCollection
    include Main::WithErrors
    include Main::WithParams
    include Main::WithRouting
    include Main::BulkAction
    RailsAdmin.actions.each do |action|
      include Main.const_get("#{action.key.to_s.camelize}Action")
    end

    # TODO https://github.com/sfcgeorge/rails_admin-state_machines-audit_trail
    before_action :set_model, except: RailsAdmin.actions(:root).map(&:name)
    before_action :set_object, only: RailsAdmin.actions(:member).map(&:name)
    before_action :prepare_action, except: :bulk_action
    before_action :check_for_cancel
    around_action :use_model_time_zone

    delegate :default_theme, to: 'RailsAdmin.config'

    helper_method :main_action, :main_section, :main_fields

    def admin?
      true
    end

    def set_model
      @model_name = params[:model_name].to_admin_name
      raise ModelNotFound unless (@abstract_model = AbstractModel.find(@model_name))
      raise ModelNotFound unless (@model = @abstract_model.model).visible?
    end

    def set_object
      raise ObjectNotFound unless (@object = @abstract_model.get(params[:id]))
    end

    def main_action
      @main_action ||= ActiveSupport::StringInquirer.new(@action.main_name)
    end

    def main_section
      @main_section ||= @model.send(main_action).with(object: @object)
    end

    def main_fields
      @main_fields ||= main_section.visible_fields
    end

    def model_cookie
      @model_cookie ||= ActiveSupport::JSON.decode(cookies["js.#{params[:model_name]}"] || '{}').with_indifferent_access
    end

    def clear_model_cookie
      cookies["js.#{params[:model_name]}"] = { expires: 1.month.ago }
    end

    protected

    # TODO try render without going through determine_template (or a stripped down version) --> might use lower RAM
    def serve_action(name)
      prepare_action(name)
      send(name)
    end

    def set_current
      super
      set_current_value(:theme, RailsAdmin.config.available_themes)
    end

    private

    def prepare_action(name = action_name.to_sym)
      raise Pundit::NotAuthorizedError unless (@action = RailsAdmin.action(name, @abstract_model, @object))
    end

    def check_for_cancel
      if params[:_cancel] || (params[:js_bulk_action] && params[:bulk_ids].blank?)
        redirect_to_on_cancel notice: I18n.t('admin.flash.noaction')
      end
    end

    def authenticate_user!
      if Rails::Env.dev_or_test? && (user_email = ENV['DEVISE_USER']).present? && !warden.authenticated?(:user)
        sign_in User.find_by(email: user_email)
      else
        super
      end
    end

    def get_pjax_layout
      pjax_layout 'rails_admin', 'application'
    end

    def set_layout_values
      main_app_name = Config.main_app_name
      @app_name = main_app_name.is_a?(Proc) ? instance_eval(&main_app_name) : main_app_name
      @app_name ||= 'Rails Admin'
      @page_title = @page_description = "#{@abstract_model.pretty_name} | #{@app_name}"
    end

    def use_model_time_zone
      if (tz = @model.time_zone)
        Time.use_zone(tz) do
          yield
        end
      else
        yield
      end
    end
  end
end
