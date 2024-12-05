module PageFields
  class HtmlPresenter < TextPresenter
    def html(**options)
      div_(**options) {[
        pretty_actions,
        text(false).presence || p_{ pretty_blank },
      ].compact}
    end
  end
end
