# frozen_string_literal: true

class AdminController < LibController
  class TooManyRows < ::StandardError; end
  class RoutingError < ActionController::RoutingError
    def initialize(*)
      super("No route matches [#{Current.controller.request.path}]")
    end
  end

  rescue_from RoutingError, ActionController::ParameterMissing, ActiveRecord::RecordNotFound, with: :on_routing_error
  rescue_from ActiveRecord::RecordInvalid,     with: :on_record_invalid
  rescue_from ActiveRecord::StaleObjectError,  with: :on_stale_object_error
  rescue_from ActiveRecord::InvalidForeignKey, with: :on_invalid_foreign_key
  rescue_from TooManyRows,                     with: :on_too_many_rows

  authenticate

  before_action :set_action
  before_action :set_model,      if: -> { @action.model? }
  before_action :on_cancel,      if: -> { @model && params[:_cancel] }
  before_action :on_blank_bulk,  if: -> { @action.bulkable? && params[:ids].blank? && params[:id] == '_bulk' }
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
      scope = scope.discarded if (Current.discarded = @action.trash?)
      ids = params[:ids].presence
      records = case
        when @action.bulkable? && ids then (bulk = true)   && @model.get(scope, @section, ids: ids)
        when @action.member?          then (member = true) && @model.get(scope, @section, id: params[:id])
        when @action.collection?      then                    @model.search(scope, @section, **search_params)
        end
    end
    @presenters = records.select_map do |record|
      next unless (presenter = record.admin_presenter).allowed?
      presenter
    end
    raise RoutingError if bulk && @presenters.empty?
    raise RoutingError if (@new || member) && (@presenter = @presenters.first).nil?
    @section = @section.with(presenter: @presenter, presenters: @presenters)
  end

  def set_attributes
    return unless (@attributes = params[@model.param_key]).present?
    fields = @section.fields.reject(&:readonly?)
    sanitize_attributes fields, @attributes
    fields.select(&:nested?).group_by(&:through).each do |through, fields|
      next unless (attributes = @attributes["#{through}_attributes"])
      sanitize_attributes fields, attributes, nested: true
    end
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

  def action_type_object
    @action_type_object ||= case
      when @new       then [:collection, @presenter]
      when @presenter then [:member,     @presenter]
      when @model     then [:collection, @model]
      else                 [:root, nil]
      end
  end

  def on_routing_error
    redirect_back
  end

  def on_cancel
    redirect_back notice: t('admin.flash.noaction')
  end
  alias_method :on_blank_bulk, :on_cancel

  def on_update_success
    if params["_#{action_name}"]
      flash.now[:notice] = admin_notice
      render action_name
    elsif params[:_save] then redirect_back notice: admin_notice
    elsif params[:_new]  then redirect_to @model.url_for(:new), notice: admin_notice
    elsif params[:_edit] then redirect_to @presenter.url_for(:edit), notice: admin_notice
    end
  end

  def on_record_invalid
    render_error
  end

  def on_stale_object_error
    @presenter.errors.add :base, :already_modified_html
    @presenter.lock_version = @presenter.lock_version_was
    render_error
  end

  def on_invalid_foreign_key
    @presenter.errors.add :base, :dependency_constraints
    render_error
  end

  def on_too_many_rows(exception)
    if @action.export?
      redirect_back alert: exception.message
    else
      response.set_header('X-Status-Reason', exception.message)
      head 413
    end
  end

  def render_error
    flash.now[:alert] = admin_alert(@presenter)
    render action_name, status: :not_acceptable
  end

  def admin_notice(presenters = nil, action = nil)
    count = Array.wrap(presenters).size
    super(@model.label(count == 0 ? 1 : count), action)
  end

  def admin_alert(presenters, action = nil)
    presenters = Array.wrap(presenters)
    count = presenters.size
    super(presenters, @model.label(count == 0 ? 1 : count), action)
  end

  def _back
    super || @action.trash? && @model&.allowed_url(:trash) || @model&.allowed_url(:index)
  end

  def sanitize_attributes(fields, params, nested: false)
    return unless params.present?
    params.slice! *fields.map(&(nested ? :column_name : :method_name))
    params.permit!
    fields.each{ |field| field.parse_input! params }
  end
end
