module LinkHelper
  def edit_user_link
    return unless Current.logged_in?
    css = 'edit_user_link'
    admin_controller = controller.try(:admin?)
    if defined?(MixAdmin) && Current.user.admin?
      css << ' pjax' if admin_controller
      path = admin_path_for(:edit, Current.user)
      title = t('user.admin')
    elsif MixUser.config.devise_modules.include? :registerable
      css << ' pjax' unless admin_controller
      path = edit_user_path
    else
      return
    end
    a_(class: css, href: path, title: title) {[
      i_('.fa.fa-user'),
      span_(Current.user.email)
    ]}
  end

  def user_view_link
    return unless defined?(MixAdmin) && !Current.controller.try(:admin?)
    if Current.as_user?
      a_ href: "?_role=false" do
        span_ '.label.label-danger', t('user.quit_preview')
      end
    elsif Current.user.admin?
      a_ href: "?_role=user" do
        span_ '.label.label-primary', t('user.enter_user_view')
      end
    end
  end

  def admin_view_link
    return unless defined?(MixAdmin) && Current.controller.try(:admin?)
    if Current.as_admin?
      a_ href: "?_role=false" do
        span_ '.label.label-danger', t('user.quit_preview')
      end
    elsif Current.user.deployer?
      a_ href: "?_role=admin" do
        span_ '.label.label-primary', t('user.enter_admin_view')
      end
    end
  end

  def admin_link
    if defined?(MixAdmin) && Current.user.admin?
      a_ href: RailsAdmin.root_path do
        span_ '.label.label-primary', t('user.admin')
      end
    end
  end

  def admin_path_for(action, object, **params)
    Current.controller_was = Current.controller
    Current.controller = RailsAdmin::MainController.new unless Current.controller_was.try(:admin?)
    case object
    when Class, String, Symbol
      Current.controller.authorized_path_for(action, object, **params)
    else
      Current.controller.authorized_path_for(action, object.class, object, **params)
    end
  ensure
    Current.controller = Current.controller_was
    Current.controller_was = nil
  end
end
