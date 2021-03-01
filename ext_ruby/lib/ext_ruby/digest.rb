module Digest
  def self.sha1_hex(*args)
    SHA1.hexdigest(args.map{ |v| v.nil? ? '?' : v }.join('.'))
  end

  def self.sha256_hex(*args)
    SHA256.hexdigest(args.map{ |v| v.nil? ? '?' : v }.join('.'))
  end
end
