module PageFields
  class TextPresenter < PageFieldPresenter
    def html(only_text: false, **options)
      escape = options.delete(:escape)
      div_(options) {[
        (pretty_actions(:div) unless only_text),
        text(escape).presence || pretty_blank,
      ]}
    end

    def text(escape = true)
      escape ? object.text : object.text&.html_safe
    end
  end
end
