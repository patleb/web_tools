MonkeyPatch.add{['railties', 'lib/rails/generators/rails/app/templates/public/404.html', '41e6541b07f9c3b306a517917eedb53d7c7bfa006faf6673aaad98c9d96f7023']}
MonkeyPatch.add{['railties', 'lib/rails/generators/rails/app/templates/public/422.html', '848f8a124ddb3a76d24a7eca39f93cef89c4fba00e0cd0b2f0af37433fb88e89']}
MonkeyPatch.add{['railties', 'lib/rails/generators/rails/app/templates/public/500.html', 'ef38a03155fab5fa59fe6c823f948893fe260204a87860c55522cdeb5672c959']}

module ActionController
  module WithStatus
    class RequestTimeoutError < StandardError; end
    class InternalServerError < StandardError; end

    def render_400(*)
      render_404(status: 400)
    end

    def render_404(*, status: 404)
      # do not log these errors, they are already in nginx log
      respond_to do |format|
        format.text { render plain: template_status_plain(status), status: status }
        format.html { render html: template_status_html(status), status: status }
        format.any  { head status }
      end
    end

    def render_408(exception = RequestTimeoutError.new)
      log exception
      respond_to do |format|
        format.text do
          render plain: template_status_plain(408), status: 408
        end
        format.html do
          self.response_body = nil # make sure that there is no DoubleRenderError
          render html: template_status_html(408), status: 408
        end
        format.any do
          if params[:file]
            output = "#{t('rescue.408.title')}: #{t('rescue.408.problem')} #{t('rescue.408.solution')}"
            send_data output, type: 'text/plain', filename: 'request_timeout.txt'
          else
            head 408
          end
        end
      end
    end

    def render_500(exception = InternalServerError.new)
      case response.status
      when 400 then return render_400
      when 422 then status = 422
      else          status = 500
      end
      log exception
      respond_to do |format|
        format.text do
          render plain: template_status_plain(status), status: status
        end
        format.html do
          self.response_body = nil # make sure that there is no DoubleRenderError
          render html: template_status_html(status), status: status
        end
        format.any do
          head status
        end
      end
    end

    def healthcheck
      head :ok
    end

    private

    def log(exception, **)
      ExtRails.config.default_logger? ? Rails.logger.error(exception.backtrace_log) : raise(NotImplementedError)
    end

    def template_status_plain(status, title: I18n.t("rescue.#{status}.title"), problem: I18n.t("rescue.#{status}.problem"), solution: I18n.t("rescue.#{status}.solution"))
      [ "#{title} (#{I18n.t("rescue.#{status}.status").presence || status})",
        problem,
        solution
      ].join("\n")
    end

    def template_status_html(status, title: t("rescue.#{status}.title"), problem: t("rescue.#{status}.problem"), solution: t("rescue.#{status}.solution"))
      helpers.instance_eval do
        html_ {[
          head_ {[
            title_("#{title} (#{t("rescue.#{status}.status").presence || status})"),
            meta_(name: 'viewport', content: 'width=device-width,initial-scale=1'),
          ]},
          body_('.rails-default-error-page') {[
            template_status_css,
            div_('.dialog') {[
              div_ {[
                h1_(title),
                p_(problem)
              ]},
              p_(solution)
            ]}
          ]}
        ]}
      end
    end
  end
end
