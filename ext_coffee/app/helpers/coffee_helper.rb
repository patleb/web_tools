module CoffeeHelper
  def js_i18n(*scopes)
    ((@@js_i18n ||= {})[Current.locale] ||= {})[scopes] ||= begin
      div_('.js_i18n', data: {
        value: scopes.each_with_object(t('js', default: {})) do |scope, all|
          all.merge! t('js', scope: scope, default: {})
        end
      })
    end
  end

  def js_routes
    div_('.js_routes', data: { value: ExtCoffee.config.routes })
  end

  def no_turbolinks
    script_(src: 'js/no_turbolinks.js', defer: true)
  end
end
