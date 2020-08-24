class PagesController < MixPage.config.parent_controller.constantize
  include MixTemplate::WithPjax
  include MixTemplate::WithLayoutValues

  def show
    if page_exists?
      load_page
      if @page.published? || Current.user.admin?
        render layout: @page.layout.view, template: @page.view
      else
        render_404
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

  def page_exists?
    PageTemplate.exists? uuid: params[:uuid]
  end

  def load_page
    @page = PageTemplate.with_contents.find_by! uuid: params[:uuid]
  end
end
