module Kernel
  def i18n_for(scopes)
    scopes.each_with_object({}) do |(scope, keys), memo|
      if keys.is_a? Hash
        keys.each do |key, values = {}|
          if key.nil?
            memo.merge! i18n_for(scope => values)
          else
            memo[key] = t(key, scope: scope, **values)
          end
        end
      else
        Array.wrap(keys).each do |key|
          memo[key] = t(key, scope: scope)
        end
      end
    end
  end
end
