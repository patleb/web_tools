module PageFields
  class TextPresenter < PageFieldPresenter
    def render(**options)
      return super if block_given?
      super **options do |options, actions|
        div_(options) {[
          actions,
          (ascii :space if actions),
          record.text.presence || pretty_blank,
        ]}
      end
    end
  end
end
