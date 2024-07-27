Oj.optimize_rails

if defined?(Rails.env) && Rails.env.development?
  $tracer = TracePoint.new(:c_call) do |tp|
    p [tp.lineno, tp.event, tp.defined_class, tp.method_id]
  end
end
