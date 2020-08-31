class PagesController < MixPage.config.parent_controller.constantize
  include MixTemplate::WithPjax
  include MixTemplate::WithLayoutValues

  before_action :render_pjax_reload, if: :pjax_reload?

  def show
    load_state
    if authorized?
      if redirect?
        redirect_to @state.to_url, status: redirect_status
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
    @state && (@state.kept? && @state.published? || Current.user.admin? && authorized_path?)
  end

  def authorized_path?
    RailsAdmin::MainController.new.authorized_path_for(:show_in_app, @state.class, @state)
  end

  def redirect?
    @state.slug != params[:slug]
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
