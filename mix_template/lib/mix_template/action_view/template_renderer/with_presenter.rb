module ActionView::TemplateRenderer::WithPresenter
  private

  def render_template(view, template, layout_name, locals)
    Current.view = view
    c = view.controller
    if c.respond_to?(:template_virtual_path) && !view.instance_variable_defined?(:@p)
      c.template_virtual_path ||= template.try(:virtual_path)
      view.instance_variable_set :@p, c.presenter_class&.new
    end
    super
  end
end

ActionView::TemplateRenderer.prepend ActionView::TemplateRenderer::WithPresenter
