module PageFields
  class RichTextPresenter < TextPresenter
    def html(only_text: false, weight: 5, **options)
      weight = 1 if weight < 1
      weight = 5 if weight > 5
      div_(options) {[
        (pretty_actions(:div) unless only_text),
        title(weight),
        subtitle(weight + 1),
        text(false).presence || p_{ pretty_blank },
      ].compact}
    end

    def title(weight)
      text = object.title
      with_tag("h#{weight}"){ text } if text.present?
    end

    def subtitle(weight)
      text = object.subtitle
      with_tag("h#{weight}"){ b_{ text } } if text.present?
    end
  end
end
