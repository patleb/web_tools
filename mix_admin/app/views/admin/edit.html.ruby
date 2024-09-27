# frozen_string_literal: true

form_(action: @presenter.url_for(action_name), multipart: true, remote: true, as: @presenter.record) {[
  input_(type: 'hidden', name: '_back', value: back_path, as: false),
  @section.groups.map do |group|
    group.fieldset
  end,
]}
