# frozen_string_literal: true

class AdminController < LibController
  class RoutingError < ActionController::RoutingError
    def initialize(*)
      super("No route matches [#{Current.controller.request.path}]")
    end
  end

  rescue_from RoutingError, ActionController::ParameterMissing, ActiveRecord::RecordNotFound, with: :render_404
  rescue_from ActiveRecord::RecordInvalid, with: :on_record_invalid
  rescue_from ActiveRecord::StaleObjectError, with: :on_stale_object_error

  authenticate

  before_action :set_action
  before_action :set_model, if: -> { @action.model? }
  before_action :redirect_on_cancel
  before_action :set_presenters, if: -> { @action.presenters? }
  before_action :set_attributes, if: -> { defined?(@new) && (@new || @action.member?) }

  attr_reader :action

  helper_method :action, :action_type, :action_object, :search_params

  Admin::Action.all.each do |action|
    class_eval(&action.controller)
  end

  def root_path
    admin_root_path
  end

  def action_type
    action_type_object.first
  end

  def action_object
    action_type_object.last
  end

  def search_params
    { q: params[:q], f: params[:f], s: params[:s], r: params[:r] }.compact_blank
  end

  protected

  def set_action
    @action = Admin::Action.find(action_name.to_sym)
  end

  def redirect_on_cancel
    redirect_back notice: t('admin.flash.noaction') if params[:_cancel]
  end

  def set_model
    model_name = params.require(:model_name).to_admin_name
    raise RoutingError unless MixAdmin.config.models_pool.include? model_name
    raise RoutingError unless (@model = model_name.to_const.admin_model).allowed?
    @section = @model.section(@action.section_name)
  end

  def set_presenters
    if (@new = @action.new?)
      records = [@model.build]
    else
      scope = policy_scope(@model.scope)
      records = case
        when bulk?               then (bulk = true)   && @model.get(scope, @section, ids: params[:ids])
        when @action.member?     then (member = true) && @model.get(scope, @section, id: params[:id])
        when @action.collection? then                    @model.search(scope, @section, **search_params)
        end
    end
    @presenters = records.select_map do |record|
      next unless (presenter = record.admin_presenter).allowed?
      presenter
    end
    raise RoutingError if bulk && @presenters.empty?
    raise RoutingError if (@new || member) && (@presenter = @presenters.first).nil?
    @section = @presenter ? @section.with(presenter: @presenter) : @section.with(presenters: @presenters)
  end

  def set_attributes
    return unless (@attributes = params[@model.param_key]).present?
    fields = @section.fields.reject(&:readonly?)
    @attributes.slice! *fields.flat_map(&:allowed_methods).uniq
    @attributes.permit!
    fields.each{ |field| field.parse_input! @attributes }
  end

  def set_meta_values
    app_name = MixAdmin.config.main_app_name
    app_name = instance_eval(&app_name) if app_name.is_a? Proc
    title = case action_type
      when :member     then @model.label
      when :collection then @new ? @model.label : @model.label_plural
      when :root       then @action.title(:menu)
      end
    (@meta ||= {}).merge!(
      root: root_path,
      app: app_name,
      title: [title.upcase_first, app_name].compact.join(' | '),
      scope: :admin,
    )
  end

  private

  # NOTE params[:id] must be present for member actions, but is ignored and set to 'bulk' by default
  def bulk?
    @action.bulkable? && params[:ids].present?
  end

  def action_type_object
    @action_type_object ||= case
      when @new       then [:collection, @presenter]
      when @presenter then [:member,     @presenter]
      when @model     then [:collection, @model]
      else                 [:root, nil]
      end
  end

  def on_success
    notice = success_notice(@model.label)
    if params["_#{action_name}"]
      flash.now[:notice] = notice
      render action_name
    elsif params[:_save] then redirect_back notice: notice
    elsif params[:_new]  then redirect_to @model.url_for(:new), notice: notice
    elsif params[:_edit] then redirect_to @presenter.url_for(:edit), notice: notice
    end
  end

  def on_record_invalid

  end

  def on_stale_object_error

  end

  def _back
    super || @model&.allowed_url(:index)
  end
end
