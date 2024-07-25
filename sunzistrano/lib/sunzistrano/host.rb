module Host
  VAGRANT  = 'vagrant-hostmanager'
  SERVER   = 'sh:dns-set_hosts-server'
  HOSTNAME = 'sh:dns-set_hosts-hostname'
  MASTER   = 'sh:dns-set_hosts-master'

  def self.domains
    @domains ||= constants.each_with_object({}.with_indifferent_access) do |constant, memo|
      tag = const_get(constant)
      first, last = "#{tag}-start", "#{tag}-end"
      list = Pathname.new('/etc/hosts').readlines
      list.select!{ |line| true if (line.include?(first) .. line.include?(last)) }
      next if list.empty?
      memo[constant.to_s.underscore] = list[1..-2]
        .reject(&:blank?)
        .map(&:split)
        .map{ |(ip, name)| [name, ip] }
        .sort_by(&:first)
        .to_h
    end
  end
end
