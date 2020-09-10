class PageFieldTextPresenter < PageFieldPresenter
  def render
    text = block_given? ? yield(object) : object.text
    super{ text }
  end
end
