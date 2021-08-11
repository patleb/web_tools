# TODO index (search), form (create, show, update, destroy, index)
# https://dba.stackexchange.com/questions/206616/optimize-a-trigram-search-with-custom-sort-order
class PagesController < MixPage.config.parent_controller.constantize
  before_action :load_state
  before_action :authorized_page!

  def pages?
    true
  end

  def show
    if redirect?
      redirect_to_page status: redirect_status
    elsif stale_state? # TODO cache https://vitobotta.com/2020/10/04/full-page-caching-in-rails-part-2-memcached-and-middleware/
      load_page
      render template: @page.template
    end
  end

  def field_create
    field = PageField.new(field_params)
    return on_not_authorized unless can? :create, field

    if field.save
      return on_not_authorized unless can? :edit, field
      on_success(field, :edit)
    else
      on_save_error(field, :new)
    end
  end

  def field_update
    field = PageField.find(params[:id])
    return on_not_authorized unless can? :edit, field

    if field.update(field_params)
      on_success(field, :edit)
    else
      on_save_error(field, :edit)
    end
  rescue ActiveRecord::RecordNotFound
    on_field_not_found
  end

  def root_path
    pages_root_path
  end

  protected

  def get_pjax_layout
    pjax_layout(@page ? @page.layout.view : MixPage.config.layout)
  end

  private

  def set_layout_values
    super
    return unless @page
    @page_title = "#{@page.title} | #{@app_name}"
    @page_description = @page.description || @page_title
  end

  def on_success(field, action)
    respond_to do |format|
      format.html { redirect_to admin_path_for(action, field), params: { _back: true } }
      format.json { render json: { flash: { success: success_notice(field, action) } } }
    end
  end

  def on_not_authorized
    handle_save_error I18n.t('admin.flash.not_allowed')
  end

  def on_save_error(field, action)
    handle_save_error error_notice(field, action)
  end

  def on_field_not_found
    handle_save_error I18n.t('admin.flash.object_not_found', model: 'PageField', id: params[:id])
  end

  def handle_save_error(notice)
    respond_to do |format|
      format.html { redirect_to_page flash: { error: notice } }
      format.json { render json: { flash: { error: notice } }, status: :not_acceptable }
    end
  end

  def success_notice(field, action)
    admin_success_notice(field.class.model_name.human, action)
  end

  def error_notice(field, action)
    admin_error_notice(field, field.class.model_name.human, action)
  end

  def field_params
    @field_params ||= if request.post?
      params.require(:page_field).permit(:type, :name, :page_id)
    else
      params.require(:page_field).permit(:list_prev_id, :list_next_id)
    end
  end

  def authorized_page!
    render_404 unless @state.try(:show?)
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
    return true unless pjax?
    return true if Rails.env.dev_or_test?
    return true if !Current.as_user? && Current.user.admin?
    stale? @state, etag: Server.current_version, template: @state.template
  end

  def load_state
    @state = PageTemplate.find_with_state_by_uuid_or_view(params[:uuid], params[:slug])
  end

  def load_page
    @page = PageTemplate.find_with_content(@state.id)
    remove_instance_variable(:@state)
  end
end
