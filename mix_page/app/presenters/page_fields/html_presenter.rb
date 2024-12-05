module PageFields
  class HtmlPresenter < TextPresenter
    def render(**options)
      return super if block_given?
      super **options do |options, actions|
        div_(options) {[
          actions,
          (ascii :space if actions),
          record.text&.html_safe.presence || p_{ pretty_blank },
        ]}
      end
    end
  end
end
