module PageFields
  class RichTextPresenter < TextPresenter
    def html(weight: 5, **options)
      weight = 1 if weight < 1
      weight = 5 if weight > 5
      div_(options) {[
        header(weight, :title),
        header(weight + 1, :subtitle),
        text(false).presence || p_{ pretty_blank },
        pretty_actions(:div),
      ].compact}
    end

    def header(weight, name)
      text = object.send(name)
      with_tag("h#{weight}"){ text } if text.present?
    end
  end
end
