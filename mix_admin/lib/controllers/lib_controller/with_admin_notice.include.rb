module LibController::WithAdminNotice
  def admin_notice(name, action = nil)
    t('admin.flash.successful', name: name, action: t("admin.actions.#{action || action_name}.done")) << '.'
  end

  def admin_alert(objects, name, action = nil)
    lines = [t('admin.flash.error', name: name, action: t("admin.actions.#{action || action_name}.done"))]
    lines.concat Array.wrap(objects).flat_map{ |object| object.errors.full_messages }.compact_blank
    message = lines.join(".\n")
    message << '.'.html_safe unless message.match? /\s*\.$/
    message
  end
end
