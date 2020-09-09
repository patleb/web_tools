class PagesController < MixPage.config.parent_controller.constantize
  include MixTemplate::WithPjax
  include MixTemplate::WithLayoutValues

  ERROR_SEPARATOR = RailsAdmin::Main::WithRouting::ERROR_SEPARATOR

  before_action :load_state
  before_action :authorized_page!

  def show
    if redirect?
      redirect_to_page status: redirect_status
    elsif stale_state? # TODO cache
      load_page
      render layout: @page.layout.view, template: @page.view # TODO pjax
    end
  end

  def field_create
    field = PageField.new(field_params)
    return redirect_to_on_not_authorized unless authorized? :new, field

    if field.save
      return redirect_to_on_not_authorized unless authorized? :edit, field
      redirect_to authorized_path_for(:edit, field)
    else
      redirect_to_on_save_error(field, :new)
    end
  end

  def field_update
    field = PageField.find(params[:id])
    return redirect_to_on_not_authorized unless authorized? :edit, field

    if field.update(field_params)
      redirect_to_on_success(field, :edit)
    else
      redirect_to_on_save_error(field, :edit)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to_on_field_not_found
  end

  private

  def set_layout_values
    super
    return unless @page
    @page_title = "#{@page.title} | #{@app_name}"
    @page_description = @page.description || @page_title
  end

  def redirect_to_on_success(field, action)
    redirect_to_page flash: { success: success_notice(field, action) }
  end

  def redirect_to_on_not_authorized
    redirect_to_page flash: { error: I18n.t('admin.flash.not_allowed') }
  end

  def redirect_to_on_save_error(field, action)
    redirect_to_page flash: { error: error_notice(field, action) }
  end

  def redirect_to_on_field_not_found
    redirect_to_page flash: { error: I18n.t('admin.flash.object_not_found', model: 'PageField', id: params[:id]) }
  end

  def success_notice(field, action)
    I18n.t('admin.flash.successful', name: field.class.name, action: I18n.t("admin.actions.#{action}.done"))
  end

  def error_notice(field, action)
    notice = I18n.t('admin.flash.error', name: field.class.name, action: I18n.t("admin.actions.#{action}.done")).html_safe
    notice += ERROR_SEPARATOR + safe_join(field.errors.full_messages, ERROR_SEPARATOR) unless field.errors.empty?
    simple_format! notice
  end

  def field_params
    @field_params ||= if request.post?
      params.require(:page_field).permit(:page_id, :type, :key)
    else
      params.require(:page_field).permit(:list_previous_id, :list_next_id)
    end
  end

  def authorized_page!
    render_404 unless authorized? :show_in_app
  end

  def authorized?(action, object = @state)
    @state && (@state.kept? && @state.published? || Current.user.admin? && authorized_path_for(action, object))
  end

  def authorized_path_for(action, object = @state)
    current_controller = Current.controller
    Current.controller = RailsAdmin::MainController.new unless current_controller.try(:admin?)
    Current.controller.authorized_path_for(action, object.class, object)
  ensure
    Current.controller = current_controller
  end

  def redirect?
    @state.slug != params[:slug]
  end

  def redirect_to_page(**options)
    redirect_to @state.to_url, **options
  end

  def redirect_status
    @state.slugs.include?(params[:slug]) ? :found : :moved_permanently
  end

  def stale_state?
    Rails.env.dev_or_test? || stale?(@state, etag: MixTemplate.config.version)
  end

  def load_state
    @state = PageTemplate.state_of(params[:uuid])
  end

  def load_page
    scope = Current.user.admin? ? PageTemplate.with_discarded : PageTemplate
    @page = scope.with_content.find(@state.id)
    remove_instance_variable(:@state)
  end
end
