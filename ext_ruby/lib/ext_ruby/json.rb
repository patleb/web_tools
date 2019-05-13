if defined? Rails
  require 'active_support/json'
  require 'oj'

  Oj.optimize_rails

  if Rails.env.development?
    $tracer = TracePoint.new(:c_call) do |tp|
      p [tp.lineno, tp.event, tp.defined_class, tp.method_id]
    end
  end
else
  require 'oj'

  Oj.mimic_JSON
  Oj.add_to_json
end
