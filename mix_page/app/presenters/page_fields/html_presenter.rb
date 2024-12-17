module PageFields
  class HtmlPresenter < TextPresenter
    def rendering(**options)
      div_(options) {[
        pretty_actions,
        record.text&.html_safe.presence || p_{ pretty_blank },
      ]}
    end
  end
end
