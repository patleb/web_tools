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
  before_action :set_format
  before_action :set_model,      if: -> { @action.model? }
  before_action :on_cancel,      if: -> { @model && params[:_cancel] }
  before_action :on_blank_bulk,  if: -> { @action.bulkable? && params[:ids].blank? && params[:id] == '_bulk' }
  before_action :set_presenters, if: -> { @action.presenters? }
  before_action :set_attributes, if: -> { defined?(@new) && (@new || @action.member?) }

  attr_reader :action, :presenter, :presenters

  helper_method :action, :action_type, :action_object, :search_params

  Admin::Action.all.each do |action|
    define_method(*action.controller)
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
    @action = Admin::Action.find(action_name)
  end

  def set_format
    request.format = @action.http_format if @action.http_format
  end

  def set_model
    klass_name = params.require(:model_name).to_class_name
    raise RoutingError unless MixAdmin.config.models_pool.include? klass_name
    raise RoutingError unless (@model = klass_name.to_const.admin_model).allowed?
    @section = @model.section(@action.section_name)
  end

  def set_presenters
    if (@new = @action.new?)
      records = [@model.build]
    else
      scope = policy_scope(@model.scope)
      scope = scope.discarded if (Current.discarded = @action.trashable?)
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
      class: ("#{@model.key}_model" if @model),
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
    respond_to do |format|
      format.html { redirect_back }
      format.json { head :not_found }
    end
  end

  def on_cancel
    redirect_back notice: t('admin.flash.noaction')
  end
  alias_method :on_blank_bulk, :on_cancel

  def on_save_success
    if params["_#{action_name}"]
      @presenter.reload if @action.edit?
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
    respond_to do |format|
      format.html do
        redirect_back alert: exception.message
      end
      format.json do
        response.set_header('X-Status-Reason', exception.message)
        head 413
      end
    end
  end

  def render_error
    notice = admin_alert(@presenter || @presenters)
    respond_to do |format|
      format.html do
        flash.now[:alert] = notice
        render action_name, status: :not_acceptable
      end
      format.json do
        render json: { flash: { alert: notice } }, status: :not_acceptable
      end
    end
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

  def sanitize_attributes(fields, params, nested: false)
    return unless params.present?
    params.slice! *fields.map(&(nested ? :column_name : :method_name))
    params.permit!
    fields.each{ |field| field.parse_input! params }
  end

  def _back_path
    if (path = super)
      path if can_redirect_back? path
    elsif @model
      path = @action.trashable? && @model.allowed_url(:trash)
      path ||= @model.allowed_url(:index)
      path ||= @model.back_model&.allowed_url(:index)
      path ||  @model.back_location
    end
  end

  def can_redirect_back?(path)
    return true unless path.start_with? "#{MixAdmin.config.root_path}/"
    fragments = Rack::Utils.parse_root(path).path.split('/').compact_blank
    action_name = fragments.pop.delete_prefix '_'  # /model/:model_name/_restore
    klass_name = action_name.to_class_name         # /model/:model_name
    return can? :index, klass_name                 unless MixAdmin.config.models_pool.exclude? klass_name
    klass_name = fragments.pop.to_class_name       # /model/:model_name/:id
    return can? :show, klass_name, id: action_name unless MixAdmin.routes.has_key? action_name.to_sym
    return can? action_name, klass_name            unless MixAdmin.config.models_pool.exclude? klass_name
    klass_name = fragments.pop.to_class_name       # /model/:model_name/:id/edit
    can? action_name, klass_name, id: klass_name
  end

  def can?(action_name, klass_name, id: nil)
    return super(action_name, klass_name) unless id
    return false unless (model = klass_name.to_const!.admin_model).allowed?
    action = Admin::Action.find(action_name)
    section = model.section(action.section_name)
    scope = policy_scope(model.scope)
    scope = scope.discarded if action.trashable?
    return false unless (record = model.get(scope, section, id: id, raise_error: false).first)
    super action_name, record
  end
end
