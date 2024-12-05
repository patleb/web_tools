module PageFields
  class TextPresenter < PageFieldPresenter
    def render(**options)
      escape = options.delete(:escape){ true }
      super **options do |options, actions|
        div_(options) {[
          actions,
          (ascii :space if actions),
          text(escape).presence || pretty_blank,
        ]}
      end
    end

    private

    def text(escape)
      escape ? record.text : record.text&.html_safe
    end
  end
end
