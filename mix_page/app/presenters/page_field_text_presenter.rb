class PageFieldTextPresenter < PageFieldPresenter
  def render
    text = block_given? ? yield(object) : object.text
    text = 'New text to edit' if text.blank? && can?(:edit, object)
    super{ text }
  end
end
