module ActionView::TemplateRenderer::WithVirtualPath
  private

  def render_template(view, template, *)
    if (controller = view.controller).respond_to? :template_virtual_path
      Current.view = view
      controller.template_virtual_path ||= template.try(:virtual_path)
    end
    super
  end
end

ActionView::TemplateRenderer.prepend ActionView::TemplateRenderer::WithVirtualPath
