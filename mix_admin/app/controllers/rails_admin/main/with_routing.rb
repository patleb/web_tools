module RailsAdmin::Main::WithRouting
  extend ActiveSupport::Concern

  CONTROLLER_PATHS = %i(
    index_path
    trash_path
    new_path
    edit_path
  )
  VIEW_PATHS = %i(
    export_path
    delete_path
    bulk_action_path
    bulk_delete_path
    chart_path
    report_path
  )

  included do
    before_action :set_request_format

    delegate *VIEW_PATHS, to: :RailsAdmin

    helper_method *CONTROLLER_PATHS, *VIEW_PATHS
  end

  def root_path
    RailsAdmin.root_path
  end

  def index_path(params = self.params.permit(:model_name).with_keyword_access)
    RailsAdmin.index_path(params)
  end

  def trash_path(params = self.params.permit(:model_name).with_keyword_access)
    RailsAdmin.trash_path(params)
  end

  def new_path(params = self.params.permit(:model_name).with_keyword_access)
    RailsAdmin.new_path(params)
  end

  def edit_path(params = { id: @object.id, **self.params.permit(:model_name).with_keyword_access })
    RailsAdmin.edit_path(params)
  end

  def redirect_to_back(**options)
    redirect_to(Current.referer.presence || index_path, **options)
  end

  def redirect_to_index(**options)
    redirect_to(index_path, **options)
  end

  def redirect_to_on_cancel(**options)
    if bulk_action?
      case bulkable_type
      when :bulkable       then redirect_to_index(**options)
      when :bulkable_trash then redirect_to(trash_path, **options)
      end
    elsif @action.back_on_cancel?
      redirect_to_back(**options)
    else
      redirect_to_index(**options)
    end
  end

  def redirect_to_on_success(name = @model.label, **options)
    notice = success_notice(name)
    if params[:_add_another]
      redirect_to new_path, **options, flash: { success: notice }
    elsif params[:_add_edit]
      redirect_to edit_path, **options, flash: { success: notice }
    else
      redirect_to_back **options, flash: { success: notice }
    end
  end

  def handle_save_error(whereto, name = @model.label)
    flash.now[:error] = error_notice(name)
    request.format = :html if request.variant.modal?
    request.format = :json if request.variant.inline?
    respond_to do |format|
      format.html.modal  { render whereto, layout: false, status: :not_acceptable }
      format.html.none   { render whereto, status: :not_acceptable }
      format.json.inline { render json: { flash: { error: flash.now[:error] } }, status: :not_acceptable }
    end
  end

  def success_notice(name = @model.label, action: @action.key)
    I18n.t('admin.flash.successful', name: name, action: I18n.t("admin.actions.#{action}.done"))
  end

  def error_notice(name = @model.label, action: @action.key)
    notice = I18n.t('admin.flash.error', name: name, action: I18n.t("admin.actions.#{action}.done").html_safe)
    Array.wrap(@object || @objects).each do |object|
      # TODO check for associations as well (might not have been propagated)
      notice += %(<br>- #{object.errors.full_messages.join('<br>- ')}) unless object.errors.empty?
    end
    simple_format(notice, {}, sanitize: false)
  end

  private

  def set_request_format
    request.format = case
      when params[:json]
        :json
      when params[:csv]
        :csv
      when params[:xml]
        :xml
      when !pjax? && (params[:compact] || params[:inline])
        :json
      when (request.put? || request.post?) && params[:modal]
        :json
      when (request.get? && params[:chart])
        :json
      else
        :html
      end
    case request.format.to_sym
    when :json
      request.variant = :compact  if params[:compact]
      request.variant = :inline   if params[:inline]
      request.variant = :modal    if params[:modal]
      request.variant = :chart    if params[:chart]
      request.variant = :file     if params[:file]
    when :csv
      request.variant = :file     if params[:file]
    when :xml
      request.variant = :file     if params[:file]
    when :html
      request.variant = :more     if params[:more]
      request.variant = :inline   if params[:inline]
      request.variant = :modal    if params[:modal]
      request.variant = :chart    if params[:chart]
    end
  end
end
