class PagesController < LibController
  before_action :set_page_state
  before_action :set_format, only: :field_update
  before_action :authorize

  layout :get_page_layout

  def show
    if redirect?
      redirect_to_page status: redirect_status
    elsif render?
      set_page
      render template: @page.template
    end
  end

  def field_create
    field = PageField.new(page_id: @page_state.id, **field_new_params)
    if cannot? :new, field
      on_unauthorized
    elsif field.save
      on_save_success(field)
    else
      on_record_invalid(field, :new)
    end
  rescue ArgumentError
    on_argument_error
  end

  def field_update
    field = PageField.find(params[:id])
    if cannot? :edit, field
      on_unauthorized
    elsif field.update(field_sort_params)
      on_save_success(field)
    else
      on_record_invalid(field, :edit)
    end
  rescue ActiveRecord::RecordNotFound
    on_record_not_found
  end

  def root_path
    pages_root_path
  end

  protected

  def get_page_layout
    @page ? @page.layout.view.to_s : MixPage.config.layout
  end

  def set_meta_values
    meta = super
    return unless @page
    title = "#{@page.title} | #{meta[:app]}"
    meta.merge!(title: title, description: @page.description || title)
  end

  private

  def on_unauthorized
    handle_error t('admin.flash.not_allowed')
  end

  def on_save_success(field)
    respond_to do |format|
      format.html { redirect_to field.admin_presenter.url_for(:edit) }
      format.json { render json: { flash: { notice: admin_notice(field.admin_presenter.record_label, :edit) } } }
    end
  end

  def on_record_invalid(field, action)
    handle_error admin_alert(field, field.admin_presenter.record_label, action)
  end

  def on_argument_error
    handle_error admin_alert(nil, PageField.admin_label, :new)
  end

  def on_record_not_found
    handle_error t('admin.flash.object_not_found', model: PageField.admin_label, id: params[:id])
  end

  def handle_error(notice)
    respond_to do |format|
      format.html { redirect_to_page alert: notice }
      format.json { render json: { flash: { alert: notice } }, status: :not_acceptable }
    end
  end

  def field_new_params
    params.require(:page).require(:field).permit(:type, :name)
  end

  def field_sort_params
    params.require(:page).require(:field).permit(:list_prev_id, :list_next_id)
  end

  def authorize
    render_404 unless @page_state.try(:show?)
  end

  def redirect?
    @page_state.slug != params[:slug]
  end

  def redirect_to_page(**options)
    redirect_to @page_state.to_url, **options
  end

  def redirect_status
    @page_state.slugs.include?(params[:slug]) ? :found : :moved_permanently
  end

  def set_page
    @page = PageTemplate.with_fields.find(remove_ivar(:@page_state).id)
  end

  def set_page_state
    @page_state = PageTemplate.find_with_state_by_uuid_or_view(params[:uuid], params[:slug])
  end

  def set_format
    request.format = :json
  end

  def etag_entries
    super << @page_state.updated_at
  end
end
