module ActionDispatch::Journey::Formatter::WithParamsFix
  def generate(name, options, path_parameters, *rest)
    super(name, options.symbolize_keys.with_keyword_access, path_parameters.symbolize_keys.with_keyword_access, *rest)
  end
end

ActionDispatch::Journey::Formatter.prepend ActionDispatch::Journey::Formatter::WithParamsFix
