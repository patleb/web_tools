module ActionController
  module WithStatus
    EXCEPTION_TEMPLATES = [422, 500].freeze

    def render_404
      # do not log these errors, they are already in nginx log
      respond_to do |format|
        format.html { render html: template_status_html(404), status: :not_found }
        format.any  { head :not_found }
      end
    end

    def render_408(exception = ActionController::UnknownError.new)
      log exception, subject: :request_timeout
      respond_to do |format|
        format.html do
          self.response_body = nil # make sure that there is no DoubleRenderError
          render html: template_status_html(408), status: :request_timeout
        end
        format.any do
          if params[:file]
            output = "#{t('template.408.title')}: #{t('template.408.problem')} #{t('template.408.solution')}"
            send_data output, type: 'text/plain', filename: 'request_timeout.txt'
          else
            head :request_timeout
          end
        end
      end
    end

    def render_500(exception = ActionController::UnknownError.new)
      log exception, subject: :internal_server_error
      respond_to do |format|
        format.html do
          self.response_body = nil # make sure that there is no DoubleRenderError
          status = response.status.in?(EXCEPTION_TEMPLATES) ? response.status : 500
          render html: template_status_html(status), status: :internal_server_error
        end
        format.any { head :internal_server_error }
      end
    end

    def healthcheck
      head :ok
    end

    private

    def template_status_html(status, title: t("template.#{status}.title"), problem: t("template.#{status}.problem"), solution: t("template.#{status}.solution"))
      helpers.instance_eval do
        html_ {[
          head_ {[
            title_("#{title} (#{t("template.#{status}.status").presence || status})"),
            meta_(name: 'viewport', content: 'width=device-width,initial-scale=1'),
            template_status_css
          ]},
          body_('.rails-default-error-page') do
            div_('.dialog') {[
              div_ {[
                h1_(title),
                p_(problem)
              ]},
              p_(solution)
            ]}
          end
        ]}
      end
    end
  end
end
