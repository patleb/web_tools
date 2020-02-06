module MixTemplate
  module WithPjax
    extend ActiveSupport::Concern

    included do
      before_action :strip_pjax_param, if: :pjax?
      before_action :strip_pjax_file_params, if: :pjax_file?
      before_action :after_redirected
      after_action  :versionize

      layout :get_pjax_layout
    end

    def redirect_to(*args)
      super
      session[:_pjax] = pjax?
    end

    protected

    def get_pjax_layout
      pjax_layout 'application'
    end

    def pjax_layout(*current_layout)
      layout_path = current_layout.compact
      layout_path << 'pjax' if pjax?
      layout_path.join('/')
    end

    private

    def pjax?
      return @_pjax if defined? @_pjax
      @_pjax = request.headers['X-PJAX'].to_b || (pjax_file? && params[:_pjax].to_b)
    end

    def pjax_file?
      return @_pjax_file if defined? @_pjax_file
      @_pjax_file = params[:_pjax_file].to_b
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
      if session[:_pjax]
        @_pjax = session.delete(:_pjax)
        response.headers['X-PJAX-REDIRECT'] = request.url
      end
    end

    def versionize
      response.set_header('X-PJAX-VERSION', MixTemplate.config.version)
    end

    def reset_pjax_query_string
      request.env['QUERY_STRING'] = request.env['QUERY_STRING'].sub(/_pjax=[^&]+&?/, '')
      request.env.delete('rack.request.query_string')
      request.env.delete('rack.request.query_hash')
      request.env.delete('action_dispatch.request.query_parameters')
      request.instance_variable_set('@original_fullpath', nil)
      request.instance_variable_set('@fullpath', nil)
    end
  end
end
