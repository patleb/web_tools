module Admin
  module Fields
    class Html < Text
      def input_control(**attributes)
        [toolbar, super(**attributes, 'data-disable': true)]
      end

      def input_css_class
        super << 'js_markdown'
      end

      private

      def toolbar
        div_('.js_markdown_toolbar', toolbar_actions.select_map do |action, icon_name|
          next unless icon_name
          button_('.btn.btn-xs.btn-square.btn-ghost', icon(icon_name),
            class: "js_#{action}", title: t(action, scope: 'markdown_toolbar'), type: 'button', 'data-disable': true
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
          multimedia: ('image' if model.allowed?(:upload)),
        }
      end
    end
  end
end
