class PageFieldPresenter < ActionPresenter::Base[:@page, :@virtual_path]
  def render
    raise NotImplementedError
  end

  def dom_class
    super(object)
  end
end
