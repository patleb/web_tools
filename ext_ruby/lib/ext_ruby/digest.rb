module Digest
  def self.md5_hex(*args)
    MD5.hexdigest(args.map{ |v| v.nil? ? '?' : v }.join('.'))
  end
end
