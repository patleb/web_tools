module MixTemplate
  module WithPjax
    extend ActiveSupport::Concern

    included do
      before_action :strip_pjax_param, if: :pjax?
      before_action :strip_pjax_file_params, if: :pjax_file?
      before_action :after_redirected, if: :pjax_redirect?
      before_action :render_pjax_reload, if: :pjax_reload?

      layout :get_pjax_layout

      helper_method :pjax?
    end

    def redirect_to(options = {}, response_options = {})
      options = Rack::Utils.merge_url(options, params: { _pjax_redirect: true }) if pjax?
      super(options, response_options)
    end

    def render_pjax_reload
      render html: '<html>'.html_safe
    end

    protected

    def get_pjax_layout
      pjax_layout 'application'
    end

    def pjax_layout(*current_layout)
      layout_path = current_layout.compact
      layout_path << 'pjax' if pjax_layout?
      layout_path.join('/')
    end

    private

    def pjax_layout?
      pjax? && !pjax_reload?
    end

    def pjax?
      return @_pjax if defined? @_pjax
      @_pjax = request.headers['X-PJAX'].to_b || pjax_file?
    end

    def pjax_file?
      return @_pjax_file if defined? @_pjax_file
      @_pjax_file = request.headers['X-PJAX-FILE'].to_b
    end

    def pjax_redirect?
      return @_pjax_redirect if defined? @_pjax_redirect
      @_pjax_redirect = params.truthy?(:delete, :_pjax_redirect)
    end

    def pjax_reload?
      return @_pjax_reload if defined? @_pjax_reload
      @_pjax_reload = params.truthy?(:delete, :_pjax_reload)
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
      request.env['QUERY_STRING'] = request.env['QUERY_STRING'].gsub(/_pjax\w*=\w+(&|$)/, '').sub(/\?$/, '')
      request.env.delete('rack.request.query_string')
      request.env.delete('rack.request.query_hash')
      request.env.delete('action_dispatch.request.query_parameters')
      request.instance_variable_set('@original_fullpath', nil)
      request.instance_variable_set('@fullpath', nil)
    end
  end
end
