def require_shakapacker
  no_pack = (ENV['PACK'] == 'false')
  require 'shakapacker' unless no_pack
  yield(no_pack) if block_given?
  require 'ext_shakapacker' unless no_pack
end
