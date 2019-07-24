module Args
  AS_ARG = %i(req opt).freeze
  AS_KEYARG = %i(keyreq key).freeze

  def method_args(name)
    method(name).parameters.select{ |arg| AS_ARG.include? arg.first }.map(&:last)
  end

  def method_keyargs(name)
    method(name).parameters.select{ |arg| AS_KEYARG.include? arg.first }.map(&:last)
  end
end

class Object
  extend Args
  include Args
end
