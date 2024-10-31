# frozen_string_literal: true

module Admin
  module Sections
    class New < Show
      def render
        form_(action: presenter.url, multipart: true, remote: true, back: true, as: presenter.record) {[
          groups.map do |group|
            group.fieldset
          end,
          buttons(
            save: model.save_label,
            new: model.allowed?(:new) && model.save_and_new_label,
            edit: model.allowed?(:edit) && model.save_and_edit_label,
            cancel: model.cancel_label,
          ),
        ]}
      end
    end
  end
end
