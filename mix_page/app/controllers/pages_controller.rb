class PagesController < MixPage.config.parent_controller.constantize
  include MixTemplate::WithPjax
  include MixTemplate::WithLayoutValues

  def show
    load_state
    if authorized?
      if redirect?
        redirect_to @state.to_url, status: :moved_permanently
      elsif stale_state? # TODO cache
        load_page
        render layout: @page.layout.view, template: @page.view # TODO pjax
      end
    else
      render_404
    end
  end

  private

  def set_layout_values
    super
    return unless @page
    @page_title = "#{@page.title} | #{@app_name}"
    @page_description = @page.description || @page_title
  end

  def authorized?
    @state && ((@state.kept? && @state.published?) || Current.user.admin?)
  end

  def redirect?
    @state.slug != params[:slug]
  end

  def stale_state?
    Rails.env.dev_or_test? || stale?(@state, etag: MixTemplate.config.version)
  end

  def load_state
    @state = PageTemplate.state_of(params[:uuid])
  end

  def load_page
    scope = Current.user.admin? ? PageTemplate.with_discarded : PageTemplate
    @page = scope.with_contents.find_by! uuid: @state.uuid
    remove_instance_variable(:@state)
  end
end
