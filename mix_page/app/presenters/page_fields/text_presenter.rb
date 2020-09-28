module PageFields
  class TextPresenter < PageFieldPresenter
    def html(**options)
      escape = options.delete(:escape)
      div_(options) {[
        text(escape).presence || pretty_blank,
        pretty_actions(:div),
      ]}
    end

    def text(escape = true)
      escape ? object.text : object.text&.html_safe
    end
  end
end
