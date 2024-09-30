module LibController::WithAdminNotice
  def admin_notice(name, action = action_name)
    t('admin.flash.successful', name: name, action: t("admin.actions.#{action}.done")) << '.'
  end

  def admin_alert(objects, name, action = action_name)
    lines = [t('admin.flash.error', name: name, action: t("admin.actions.#{action}.done"))]
    lines.concat Array.wrap(objects).flat_map{ |object| object.errors.full_messages }.compact_blank
    helpers.simple_format! lines.join(".\n") << '.'
  end
end
