class TemplatesController < MixTemplate.config.parent_controller.constantize
  include ActionView::Helpers::TextHelper

  ERROR_SEPARATOR = '<br>- '

  before_action :strip_pjax_param, if: :pjax?
  before_action :strip_pjax_file_params, if: :pjax_file?
  before_action :after_redirected, if: :pjax_redirect?
  before_action :render_pjax_reload, if: :pjax_reload?
  before_render :set_layout_values
  after_action  :versionize

  layout :get_pjax_layout

  helper_method :pjax?, :pjax

  def redirect_to(options = {}, response_options = {})
    if pjax?
      (response_options[:params] ||= {}).merge!(_pjax_redirect: true)
    end
    super(options, response_options)
  end

  def render_pjax_reload
    render html: '<html>'.html_safe
  end

  protected

  def get_pjax_layout
    pjax_layout('application') unless try(:skip_pjax?)
  end

  def pjax_layout(*current_layout)
    layout_path = current_layout.compact
    layout_path << 'pjax' if pjax_layout?
    layout_path.join('/')
  end

  if defined? MixAdmin
    def admin_success_notice(name, action)
      I18n.t('admin.flash.successful', name: name, action: I18n.t("admin.actions.#{action}.done"))
    end
    helper_method :admin_success_notice

    def admin_error_notice(objects, name, action = nil)
      notice = action ? I18n.t('admin.flash.error', name: name, action: I18n.t("admin.actions.#{action}.done")) : name
      Array.wrap(objects).each do |object|
        notice += ERROR_SEPARATOR + object.errors.full_messages.join(ERROR_SEPARATOR) unless object.errors.empty?
      end
      simple_format! notice
    end
    helper_method :admin_error_notice
  end

  private

  def get_root_path
    @root_path || set_root_path
  end

  def set_root_path
    @root_path = respond_to?(:root_path) ? root_path : app_root_path
  end

  def set_layout_values
    set_root_path
    @root_pjax = true
    @app_name = @page_title = @page_description = Rails.application.title
    @page_web_app_capable = MixTemplate.config.web_app_capable
    @page_version = MixTemplate.config.version
  end

  def versionize
    response.set_header('X-PAGE-VERSION', MixTemplate.config.version)
  end

  def pjax_layout?
    pjax? && !pjax_reload?
  end

  def pjax?
    return @_pjax if defined? @_pjax
    @_pjax = !try(:skip_pjax?) && (request.headers['X-PJAX'].to_b || pjax_file?)
  end
  alias_method :pjax, :pjax?

  def pjax_file?
    return @_pjax_file if defined? @_pjax_file
    @_pjax_file = !try(:skip_pjax?) && request.headers['X-PJAX-FILE'].to_b
  end

  def pjax_redirect?
    return @_pjax_redirect if defined? @_pjax_redirect
    @_pjax_redirect = !try(:skip_pjax?) && params.truthy?(:delete, :_pjax_redirect)
  end

  def pjax_reload?
    return @_pjax_reload if defined? @_pjax_reload
    @_pjax_reload = !try(:skip_pjax?) && params.truthy?(:delete, :_pjax_reload)
  end

  def strip_pjax_param
    params.delete(:_pjax)
    reset_pjax_query_string
  end

  def strip_pjax_file_params
    params.delete(:_pjax)
    params.delete(:_pjax_file)
    params.delete('X-Requested-With')
    params.delete('X-HTTP-Accept')
  end

  def after_redirected
    response.set_header('X-PJAX-REDIRECT', request.url)
  end

  def reset_pjax_query_string
    request.env['QUERY_STRING'] = request.env['QUERY_STRING'].gsub(/_pjax\w*=\w+(&|$)/, '').sub(/[?&]$/, '')
    request.env.delete('rack.request.query_string')
    request.env.delete('rack.request.query_hash')
    request.env.delete('action_dispatch.request.query_parameters')
    request.instance_variable_set('@original_fullpath', nil)
    request.instance_variable_set('@fullpath', nil)
  end
end
