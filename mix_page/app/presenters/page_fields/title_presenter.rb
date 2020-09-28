module PageFields
  class TitlePresenter < TextPresenter
    def html(weight: 5, **options)
      title = text.presence || pretty_blank
      weight = 1 if weight < 1
      weight = 6 if weight > 6
      div_(options) {[
        pretty_actions(:span),
        with_tag("h#{weight}"){ title },
      ]}
    end
  end
end
