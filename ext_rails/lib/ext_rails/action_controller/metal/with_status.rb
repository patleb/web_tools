MonkeyPatch.add{['railties', 'lib/rails/generators/rails/app/templates/public/400.html', 'a22162717f188b736f1d646acc2d392449a4fd6b8437da310964516b04cdc3e9']}
MonkeyPatch.add{['railties', 'lib/rails/generators/rails/app/templates/public/404.html', '0f966fd28d4c2ad94dc3351c7ebcc9a65245c96e66650072de11a214c09d7e50']}
MonkeyPatch.add{['railties', 'lib/rails/generators/rails/app/templates/public/406-unsupported-browser.html', 'd2e5e109f8908b7de017a5a21cf385db98ea9f2d8c434b11dbce4a648056d880']}
MonkeyPatch.add{['railties', 'lib/rails/generators/rails/app/templates/public/422.html', 'e38e8bc96fa0c8bbb77d13cc98c023a22ae6fc81f8e03eec686563b854da71d0']}
MonkeyPatch.add{['railties', 'lib/rails/generators/rails/app/templates/public/500.html', '28bbc92a53f2667f153049939fd0762e309f8c4c57e2bd4918db2006a98ffbec']}

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
      status
    end

    def render_408(exception = RequestTimeoutError.new, status: 408)
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
          if params[:file]
            output = [t("rescue.#{status}.title"), t("rescue.#{status}.problem"), t("rescue.#{status}.solution")].join(': ')
            send_data output, type: 'text/plain', filename: 'request_timeout.txt'
          else
            head status
          end
        end
      end
      status
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
      status
    end

    def healthcheck
      head :ok
    end

    private

    def log(exception, **)
      ExtRails.config.default_logger ? Rails.logger.error(exception.backtrace_log) : raise(NotImplementedError)
    end

    def template_status_plain(status, title: t("rescue.#{status}.title"), problem: t("rescue.#{status}.problem"), solution: t("rescue.#{status}.solution"))
      [ "#{title} (#{t("rescue.#{status}.status").presence || status})",
        problem,
        solution
      ].join("\n")
    end

    def template_status_html(status, title: t("rescue.#{status}.title"), problem: t("rescue.#{status}.problem"), solution: t("rescue.#{status}.solution"))
      helpers.instance_eval do
        html_ {[
          head_ {[
            title_("#{title} (#{t("rescue.#{status}.status").presence || status})"),
            meta_(charset: 'UTF-8'),
            meta_(name: 'viewport', content: 'width=device-width, initial-scale=1'),
            meta_(name: 'robots', content: 'noindex, nofollow'),
            meta_(name: 'turbolinks-visit-control', content: 'reload'),
            no_turbolinks,
            template_status_css,
          ]},
          body_('.rails-default-error-page') {[
            main_('.dialog') {[
              header_ {[
                h1_(title),
                p_(problem)
              ]},
              article_(solution)
            ]}
          ]}
        ]}
      end
    end
  end
end
