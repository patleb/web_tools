module PageFields
  class TextPresenter < PageFieldPresenter
    def rendering(**options)
      div_(options) {[
        pretty_actions,
        record.text.presence || pretty_blank,
      ]}
    end
  end
end
