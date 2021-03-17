# TODO https://eregon.me/blog/2019/11/10/the-delegation-challenge-of-ruby27.html
module Args
  AS_ARG = %i(req opt).freeze
  AS_KEYARG = %i(keyreq key).freeze

  def method_args(name)
    method(name).parameters.select_map{ |arg| arg.last if AS_ARG.include? arg.first }
  end

  def method_keyargs(name)
    method(name).parameters.select_map{ |arg| arg.last if AS_KEYARG.include? arg.first }
  end
end

class Object
  extend Args
  include Args
end
