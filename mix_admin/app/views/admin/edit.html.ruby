# frozen_string_literal: true

form_(action: @presenter.url_for(action_name), multipart: true, remote: true, back: true, as: @presenter.record) {[
  @section.groups.map do |group|
    group.fieldset
  end,
  admin_member_actions,
]}
