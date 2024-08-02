module ActionView::TemplateRenderer::WithVirtualPath
  private

  def render_template(view, template, *)
    Current.view = view
    controller = view.controller
    if controller.respond_to? :template_virtual_path
      controller.template_virtual_path ||= template.try(:virtual_path)
    end
    super
  end
end

ActionView::TemplateRenderer.prepend ActionView::TemplateRenderer::WithVirtualPath
