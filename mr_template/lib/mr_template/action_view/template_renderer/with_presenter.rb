module ActionView::TemplateRenderer::WithPresenter
  private

  def determine_template(options)
    template = super
    Current.view = @view
    c = @view.controller
    if c.respond_to? :template_virtual_path
      c.template_virtual_path ||= template.try(:virtual_path)
      @view.instance_variable_set :@p, c.presenter_class&.new
    end
    template
  end
end

ActionView::TemplateRenderer.prepend ActionView::TemplateRenderer::WithPresenter
