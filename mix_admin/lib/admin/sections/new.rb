# frozen_string_literal: true

module Admin
  module Sections
    class New < Show
      def member_form
        form_(action: presenter.url_for(action_name), multipart: true, remote: true, back: true, as: presenter.record) {[
          groups.map do |group|
            group.fieldset
          end,
          member_actions,
        ]}
      end

      def member_actions
        actions = {
          save: model.save_label,
          new: model.allowed?(:new) && model.save_and_new_label,
          edit: model.allowed?(:edit) && model.save_and_edit_label,
          cancel: model.cancel_label,
        }
        div_ '.member_actions' do
          actions.select_map do |name, label|
            next unless label
            input_(class: name, type: 'submit', name: "_#{name}", value: label, formnovalidate: name == :cancel)
          end
        end
      end
    end
  end
end
