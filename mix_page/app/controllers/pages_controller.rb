class PagesController < MixPage.config.parent_controller.constantize
  include MixTemplate::WithPjax
  include MixTemplate::WithLayoutValues

  def show
    if PageTemplate.exists? uuid: params[:uuid]
      @page = PageTemplate.with_contents.find_by! uuid: params[:uuid]
      render layout: @page.layout.view, template: @page.view
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
end
