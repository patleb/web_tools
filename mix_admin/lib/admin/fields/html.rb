# frozen_string_literal: true

module Admin
  module Fields
    class Html < Text
      register_option :input do
        [toolbar, __super__(:input)]
      end

      def input_css_class
        super << 'js_markdown'
      end

      def parse_input!(params)

      end

      private

      def toolbar
        div_('.js_markdown_toolbar', toolbar_actions.map do |action, icon_name|
          button_('.btn.btn-xs.btn-square', icon(icon_name),
            class: "js_#{action}", title: t(action, scope: 'markdown_toolbar'), type: 'button'
          )
        end)
      end

      def toolbar_actions
        {
          fullscreen: 'arrows-fullscreen',
          undo:       'arrow-counterclockwise',
          redo:       'arrow-clockwise',
          bold:       'type-bold',
          italic:     'type-italic',
          blockquote: 'quote',
          code:       'code-square',
          link:       'link',
          bulletlist: 'list-ul',
          multimedia: 'image',
        }
      end
    end
  end
end
