class PageFieldTextPresenter < PageFieldPresenter
  def render
    text = object.text
    text = yield if text.blank? && block_given?
    text
  end
end
